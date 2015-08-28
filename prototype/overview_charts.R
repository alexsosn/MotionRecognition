#http://stackoverflow.com/questions/5118074/reusing-a-model-built-in-r

setwd("~/Desktop/moves_protot")

#install.packages(c("changepoint", "bigmemory", "plyr"))
#install.packages(c("caret", "rpart", "rpart.plot", "tree", "randomForest", "e1071", "ggplot2", "RColorBrewer", "compiler", "tuneR"))

#library('changepoint')
# library('bigmemory')
library('plyr')

library("caret")
library("rpart")
library("rpart.plot")

library("tree")
library("randomForest")
library("e1071")
library("ggplot2")
library("RColorBrewer")
library("compiler")


readTestData <- function() {
  filenames <- list.files("valid_data/test", pattern="*.csv", full.names=TRUE)
  res <- lapply(filenames, read.motion.data)
  res <- Reduce(rbind, res)
  res.summary <- aggregateMotionData(res)
  remove(filenames, res)
  return(res.summary)
}



read.motion.data <- function(path.to.file) {
  acc <- as.data.frame(scan(path.to.file, 
                            what=list(date='', sensorName='', 
                                      activityType='', motionDirection='', onBodyPosition='', 
                                      x="", y="", z="", 
                                      t4='', t5='', t6='', 
                                      t7='', t8='', t9='', 
                                      t10='', t11='', t12='', 
                                      t13='', t14='', t15='', 
                                      t16='', t17='', t18='', t19=''), 
                            sep=',', comment.char="", multi.line=F, fileEncoding="UTF-8", 
                            na.strings="", flush=T, fill=T))
  acc$date = as.numeric(as.character(acc$date))
  acc$date = as.POSIXct(acc$date, origin="1970-01-01")
  colnames(acc)[1]<-"dates"
  acc
}


aggregateMotionData <- function(res) {
  sec <- cut(res$date, breaks='sec')
  res <- cbind(res, sec=sec)
  
  res <- rbind(res[res$sensorName == "Acceleration",], res[res$sensorName == "Gyro",], res[res$sensorName == "Gyroscope",])
  
  #counting magnitude
  res$magnitude = sqrt(as.numeric(res$x)^2+as.numeric(res$y)^2+as.numeric(res$z)^2)
  
  #counting table of predictors
  res.summary <- ddply(res, ~sec+sensorName, summarise, 
                       activity.type=names(sort(summary(activityType), decreasing = T)[1])[1],
                       mean=mean(magnitude), sd=sd(magnitude), 
                       max=max(magnitude), min=min(magnitude),
                       fft.max=max(abs(fft(magnitude)))
  )
  
  acc <-res.summary[res.summary$sensorName == "Acceleration",]
  names(acc)[4:8] <- paste(names(acc)[4:8], "_acc", sep="")
  gyro <- res.summary[res.summary$sensorName == "Gyroscope",]
  names(gyro)[4:8] <- paste(names(gyro)[4:8], "_gyro", sep="")
  gyro <- cbind(sec=gyro[,1],gyro[,4:8])
  res.summary <- merge(x = acc, y = gyro, by = "sec", all = TRUE)
  remove(acc, gyro)
  res.summary$sensorName <- as.factor(res.summary$sensorName)
  res.summary$activity.type <- as.factor(res.summary$activity.type)
#   res.summary$motion.direction <- as.factor(res.summary$motion.direction)
#   res.summary$on.body.position <- as.factor(res.summary$on.body.position)
  res.summary <- res.summary[complete.cases(res.summary),]
  
  return(res.summary)
}


drawChart <- function(data, sensorName = "Acceleration", complete.cases = F) {
  sensor.data = data[data$sensorName == sensorName,]
  sensor.data = cbind(sensor.data[,1], sensor.data[,3:8])
  if (complete.cases) {
    sensor.data = sensor.data[complete.cases(sensor.data),]
  }
  sensor.data$magnitude = sqrt(as.numeric(sensor.data$x)^2+as.numeric(sensor.data$y)^2+as.numeric(sensor.data$z)^2)
  sensor.data = sensor.data[sensor.data[,1]>=sensor.data[1,1],]
  sensor.data = sensor.data[sensor.data[,1]<=tail(sensor.data[,1],1),]
  sensor.data = sensor.data[order(sensor.data$dates),]
#   m.binseg=cpt.mean(sensor.data$magnitude, Q = 10, method='BinSeg',penalty='Manual',pen.value='1.5*log(n)')
#   plot(m.binseg, type='l', col=sensor.data$activityType, cpt.width=4, main = "Acceleration, BinSeg")
  plot(sensor.data$dates, sensor.data$magnitude, col=sensor.data$activityType, main = names(table(ldf[[i]]$activityType))[1])
  lines(sensor.data$dates, sensor.data$magnitude, col='green')
}

readTestData <- cmpfun(readTestData)
read.motion.data <- cmpfun(read.motion.data)
aggregateMotionData <- cmpfun(aggregateMotionData)
drawChart <- cmpfun(drawChart)

# for (i in 1:length(ldf)){
#   drawChart(ldf[[i]], "Acceleration", complete.cases = F)
# }
if(file.exists("aggregated_data.rda")) {
  ## load model
  load("aggregated_data.rda")
} else {
  ## (re)fit the model
  #reading data in
  filenames <- list.files("valid_data/train", pattern="*.csv", full.names=TRUE)
  
  res <- lapply(filenames, read.motion.data)
  res <- Reduce(rbind, res)
  
  #counting table of predictors
  res.summary <- aggregateMotionData(res)
  remove(filenames, res)

  # split data into train and test sets
  trainIndex = createDataPartition(res.summary$activity.type, p = .8, list = F, times = 1)
  train = res.summary[trainIndex,]
  test = res.summary[-trainIndex,]
  
  train <- res.summary[complete.cases(res.summary),]
  train <- train[train$activity.type != "Train",]
  train$activity.type <- as.factor(as.character(train$activity.type))
  
  # -- training models --
  fol <- formula(activity ~ mean_acc + sd_acc + max_acc + min_acc + fft_acc + mean_gyro + sd_gyro + max_gyro + min_gyro + fft_gyro)
  
  # Decision Tree
  model <- rpart(fol, method="class", data=train)
  
  # Random Forest
  modelF <- randomForest(fol, data=train)
  
  # SVM
  modelSVM <- svm(fol, data=train)
  
  # Naive Bayes
  modelB <- naiveBayes(fol, data=train)
  
  ### Decision Tree ###
  print(model)
  prp(model, type=2, extra=8)
  printcp(model)
  plotcp(model,upper="splits")
  
  #cut tree if needed
  #PrunedDecisionTree<-prune(DecisionTree,cp=0.0272109)
  
  predictions <- predict(model, test, type = "class")
  head(predictions)
  a1 = length(test[as.character(test$activity) == as.character(predictions),1]) / length(test[,1])
  
  ### Accuracy ###
  a1
  t1 <- table(pred = predictions, true = test$activity)
  t1
  heatmap(t1)
  
  ### Random Forest ###
  predictions <- predict(modelF, test, type = "class")
  head(predictions)
  a1 = length(test[test$activity.type == predictions,1]) / length(test[,1])
  
  ### Accuracy ###
  a1
  t2 <- table(pred = predictions, true = test$activity.type)
  t2
  heatmap(t2)
  
  ### Support Vector Machine ###
  predictions <- predict(modelSVM, test, type = "class")
  head(predictions)
  a1 = length(test[test$activity.type == predictions,1]) / length(test[,1])
  
  ### Accuracy ###
  a1
  t3 <- table(pred = predictions, true = test$activity.type)
  t3
  heatmap(t3)
  
  ### Naive Bayes ###
  predictions <- predict(modelB, test, type = "class")
  head(predictions)
  a1 = length(test[test$activity.type == predictions,1]) / length(test[,1])
  
  ### Accuracy ###
  a1
  t4 <- table(pred = predictions, true = test$activity.type)
  t4
  heatmap(t4)
  save(res.summary, test, train, model, modelF, modelSVM, modelB, file = "aggregated_data_fft.rda")
  
}

### Decision Tree ###
prp(model, type=2, extra=8)

disjoint_test <- readTestData()
predictions <- predict(model, disjoint_test, type = "class")
predictions_matrix <- predictions
head(predictions)
levels(disjoint_test$activity.type)
# <- c( "Run", "Shake", "Walk", "Automotive", "Stand")
a1 = length(disjoint_test[disjoint_test$activity.type == predictions,1]) / length(disjoint_test[,1])

### Accuracy ###
a1
table(pred = predictions, true = disjoint_test$activity.type)

### Random Forest ###
predictions <- predict(modelF, disjoint_test, type = "class")
predictions_matrix <- rbind(predictions_matrix, predictions)
head(predictions)
a1 = length(disjoint_test[disjoint_test$activity.type == predictions,1]) / length(disjoint_test[,1])

### Accuracy ###
a1
table(pred = predictions, true = disjoint_test$activity.type)

### Support Vector Machine ###
predictions <- predict(modelSVM, disjoint_test, type = "class")
predictions_matrix <- rbind(predictions_matrix, predictions)

head(predictions)
a1 = length(disjoint_test[disjoint_test$activity.type == predictions,1]) / length(disjoint_test[,1])

### Accuracy ###
a1
table(pred = predictions, true = disjoint_test$activity.type)

## Naive Bayes ##
predictions <- predict(modelB, disjoint_test, type = "class")
predictions_matrix <- rbind(predictions_matrix, predictions)

head(predictions)
a1 = length(disjoint_test[disjoint_test$activity.type == predictions,1]) / length(disjoint_test[,1])

### Accuracy ###
a1
table(pred = predictions, true = disjoint_test$activity.type)

## Majority ##
results <- apply(as.matrix(predictions_matrix), 2, function(x) {names(sort(table(as.factor(x)), decreasing = T)[1])[1]})
levels(results) <- levels(disjoint_test$activity.type)
a1 = length(disjoint_test[disjoint_test$activity.type == results,1]) / length(disjoint_test[,1])
table(pred = results, true = disjoint_test$activity.type)
