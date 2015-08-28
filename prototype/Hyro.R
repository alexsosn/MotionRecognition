library(changepoint)
library(bigmemory)

read.motion.data <- function(path.to.file) {
  acc <- as.data.frame(scan(path.to.file, 
                            what=list(date='', sensorName='', 
                                      activityType='', motionDirection='', onBodyPosition='', 
                                      x='', y='', z='', 
                                      t4='', t5='', t6='', 
                                      t7='', t8='', t9='', 
                                      t10='', t11='', t12='', 
                                      t13='', t14='', t15='', 
                                      t16='', t17='', t18='', t19=''), 
                            sep=',', comment.char="", multi.line=F, fileEncoding="UTF-8", 
                            na.strings="", flush=T, fill=T))
}

drawChart <- function(data, sensorName = "Acceleration", complete.cases = F) {
  sensor.data = data[data$sensorName == sensorName,]
  sensor.data = cbind(sensor.data[,1], sensor.data[,3:8])
  sensor.data[,1] = as.numeric(as.character(sensor.data[,1]))
  if (complete.cases) {
    sensor.data = sensor.data[complete.cases(sensor.data),]
  }
  sensor.data[,1] = as.POSIXct(sensor.data[,1], origin="1970-01-01")
  colnames(sensor.data)[1]<-"dates"
  
  sensor.data$magnitude = sqrt(as.numeric(sensor.data$x^2+as.numeric(sensor.data$y)^2+as.numeric(sensor.data$z^2)
  sensor.data = sensor.data[sensor.data[,1]>=sensor.data[1,1],]
  sensor.data = sensor.data[sensor.data[,1]<=tail(sensor.data[,1],1),]
  sensor.data = sensor.data[order(sensor.data$dates),]
  
#m.binseg=cpt.mean(sensor.data$magnitude, Q = 10, method='BinSeg',penalty='Manual',pen.value='1.5*log(n)')
#plot(m.binseg, type='l', col=sensor.data$activityType, cpt.width=4, main = "Acceleration, BinSeg")
  plot(sensor.data$dates, sensor.data$magnitude, col=sensor.data$activityType, main = "Acceleration")
  lines(sensor.data$dates, sensor.data$magnitude, col='green')
}

filenames <- list.files("valid_data/2", pattern="*.csv", full.names=TRUE)
ldf <- lapply(filenames, read.motion.data)
res <- Reduce(rbind, ldf)

sensors <- c("Acceleration", "Gyro", "Motion")

lapply(c(res, sensors), drawChart)


#par(mfrow=c(2,3))
sam = acc2[acc2[,2]=="Acceleration",][,3:5]
sam = sam[complete.cases(sam),]#[1:10000,]
dates = acc2[acc2[,2]=="Acceleration",][,1][complete.cases(sam)]#[1:10000]
time = as.POSIXct(as.numeric(dates), origin="1970-01-01")


insertRow <- function(existingDF, newrow, r) {
  existingDF[seq(r+1,nrow(existingDF)+1),] <- existingDF[seq(r,nrow(existingDF)),]
  existingDF[r,] <- newrow
  existingDF
}

data = data.frame(v1=as.numeric(sam[,1]), v2=as.numeric(sam[,2]), v3=as.numeric(sam[,3]))
data = data[complete.cases(data),]
data.pr = insertRow(data, rep(0,3), 1)
data = insertRow(data, rep(0,3), length(data[,1]))
cos = (data.pr[,1]*data[,1]+data.pr[,2]*data[,2]+data.pr[,3]*data[,3])/(sqrt(data[,1]^2+data[,2]^2+data[,3]^2)*sqrt(data.pr[,1]^2+data.pr[,2]^2+data.pr[,3]^2))
cos = cos[complete.cases(cos)]

head(cos)

WMA = c()
for (i in 1:length(cos)) {
  acc = 0
  for (j in 0:10) {
    if (!is.null(cos[i-j])) {
      acc <- acc + cos[i-j]*(10-j)
    }
  }
  WMA[i] = acc/55
}

plot(fft(cos), type='l', col='blue')

plot(WMA, type='l', col='blue', main="Accelerometer, WMA")
m.binseg=cpt.mean(WMA[complete.cases(WMA)], Q = 10, method='BinSeg', penalty='Manual', pen.value='0.01*log(n)')
plot(m.binseg, type='l', col='green', cpt.width=4, main = "Accelerometer, BinSeg, WMA")
cpts(m.binseg)

#data = sqrt(as.numeric(sam[,1])^2+as.numeric(sam[,2])^2+as.numeric(sam[,3])^2)
#plot(time, data, type="l", col="red")

#m.pelt=cpt.mean(data, method="PELT", penalty='Manual',pen.value='1.5*log(n)')
#plot(m.pelt,type='l',cpt.col='blue',xlab='Index',cpt.width=4, main = "Accelerometer, PELT")
#cpts(m.pelt)
m.binseg=cpt.mean(cos, Q = 10, method='BinSeg', penalty='Manual', pen.value='1.5*log(n)')
plot(m.binseg, type='l', col='green', cpt.width=4, main = "Accelerometer, BinSeg, cosines btw vectors")
cpts(m.binseg)

#m.segneigh=cpt.mean(data, Q=11, method='SegNeigh', penalty='Manual',pen.value='1.5*log(n)')
#plot(m.segneigh,type='l',cpt.col='red',cpt.width=4, main = "Accelerometer, SegNeigh")
#cpts(m.segneigh)

#m.binseg=cpt.mean(data)
#lines(m.binseg,type='l',cpt.col='orange',cpt.width=4)
#cpts(m.binseg)

gyro = acc2[acc2[,2]=="Gyro",][,3:5]
dategyro = acc2[acc2[,2]=="Gyro",][,1]
timegyro = as.POSIXct(as.numeric(dategyro), origin="1970-01-01")
#plot(timegyro, gyro[,1]+gyro[,2]+gyro[,3], type="l", col="green")
gyro = gyro[complete.cases(gyro),]
gyro.magnitude = sqrt(as.numeric(gyro[,1])^2+as.numeric(gyro[,2])^2+as.numeric(gyro[,3])^2)
m.binseg=cpt.mean(gyro.magnitude, Q = 10, method='BinSeg')
plot(m.binseg, type='l', col='green', cpt.width=4, main = "Gyro, BinSeg")
cpts(m.binseg)

magn = acc2[acc2[,2]=="Magnetic",][,3:5]
datemagn = acc2[acc2[,2]=="Magnetic",][,1]
timemagn = as.POSIXct(as.numeric(datemagn), origin="1970-01-01")
#plot(timemagn, log(magn[,1]*magn[,2]*magn[,3]), type="l", col="blue")
magn = magn[complete.cases(magn),]
magn.magnitude = sqrt(as.numeric(magn[,1])^2 + as.numeric(magn[,2])^2*as.numeric(magn[,3])^2)
m.binseg=cpt.mean(magn.magnitude, method='BinSeg')
plot(m.binseg, type='l', col='green', cpt.width=4, main = "Magnetometer, BinSeg")

#============================= Drow chart===========================#
drawChart <- function(name, rlimit) {
  motion = acc2[acc2[,2] == name,]
  motion = cbind(motion[,1], motion[,3:rlimit])
  motion[,1] = as.numeric(as.character(motion[,1]))
  motion = motion[complete.cases(motion),]
  motion[,1] = as.POSIXct(motion[,1], origin="1970-01-01")
  colnames(motion)[1]<-"dates"
  
  motion$magnitude = sqrt(as.numeric(motion[,2])^2+as.numeric(motion[,3])^2+as.numeric(motion[,4])^2)
  motion = motion[motion[,1]>=motion[1,1],]
  motion = motion[motion[,1]<=tail(motion[,1],1),]
  motion = motion[order(motion$dates),]
  
  m.binseg=cpt.mean(motion$magnitude, Q = 10, method='BinSeg',penalty='Manual',pen.value='1.5*log(n)')
  plot(motion$dates, motion$magnitude, type='l', col='green', main = cat(name,", Magnitude"))
  plot(m.binseg, type='l', col='green', cpt.width=4, main = cat(name,", BinSeg, Magnitude"))
  
  
  data.pr = insertRow(motion, rep(0,3), 1)
  data = insertRow(motion, rep(0,3), length(data[,1]))
  cos = (data.pr[,1]*data[,1]+data.pr[,2]*data[,2]+data.pr[,3]*data[,3])/(sqrt(data[,1]^2+data[,2]^2+data[,3]^2)*sqrt(data.pr[,1]^2+data.pr[,2]^2+data.pr[,3]^2))
  cos = cos[complete.cases(cos)]
  
  WMA = c()
  for (i in 1:length(cos)) {
    acc = 0
    for (j in 0:10) {
      if (!is.null(cos[i-j])) {
        acc <- acc + cos[i-j]*(10-j)
      }
    }
    WMA[i] = acc/55
  }
  plot(motion$dates, WMA, type='l', col='blue', main="Accelerometer, WMA")
}

drawChart("Gyro", 5)
drawChart("Motion", 17)

#============================= Motion ==============================#
motion = acc2[acc2[,2] == "Motion",]
motion = cbind(motion[,1], motion[,3:20])
motion[,1] = as.numeric(as.character(motion[,1]))
#motion = motion[complete.cases(motion),]
motion[,1] = as.POSIXct(motion[,1], origin="1970-01-01")
colnames(motion)[1]<-"dates"

motion$magnitude = sqrt(as.numeric(motion[,5])^2+as.numeric(motion[,6])^2+as.numeric(motion[,7])^2)
motion = motion[motion[,1]>=motion[1,1],]
motion = motion[motion[,1]<=tail(motion[,1],1),]
motion = motion[order(motion$dates),]

m.binseg=cpt.mean(motion$magnitude, Q = 10, method='BinSeg',penalty='Manual',pen.value='1.5*log(n)')
plot(m.binseg, type='l', col=motion$activityType, cpt.width=4, main = "Motion, BinSeg")
plot(motion$dates, motion$magnitude, col=motion$activityType, main = "Motion")
lines(motion$dates, motion$magnitude, col='green')


motion = acc2[acc2[,2] == "Acceleration",]
motion = cbind(motion[,1], motion[,3:8])
motion[,1] = as.numeric(as.character(motion[,1]))
#motion = motion[complete.cases(motion),]
motion[,1] = as.POSIXct(motion[,1], origin="1970-01-01")
colnames(motion)[1]<-"dates"

motion$magnitude = sqrt(as.numeric(motion[,5])^2+as.numeric(motion[,6])^2+as.numeric(motion[,7])^2)
motion = motion[motion[,1]>=motion[1,1],]
motion = motion[motion[,1]<=tail(motion[,1],1),]
motion = motion[order(motion$dates),]

m.binseg=cpt.mean(motion$magnitude, Q = 10, method='BinSeg',penalty='Manual',pen.value='1.5*log(n)')
plot(m.binseg, type='l', col=motion$activityType, cpt.width=4, main = "Acceleration, BinSeg")
plot(motion$dates, motion$magnitude, col=motion$activityType, main = "Acceleration")
lines(motion$dates, motion$magnitude, col='green')
#===============================Sound================================#
require(tuneR)
t = motion$magnitude
u = (2^15-1)*sin(2*pi*440*t) 
w = Wave(u, samp.rate = 8000, bit=16) 
writeWave(w,"wave.wav")



lines(motion$dates, sqrt(as.numeric(motion[,5])^2+as.numeric(motion[,6])^2+as.numeric(motion[,7])^2), type="l", col="green")
lines(motion$dates, sqrt(as.numeric(motion[,8])^2+as.numeric(motion[,9])^2+as.numeric(motion[,10])^2), type="l", col="blue")
lines(motion$dates, sqrt(as.numeric(motion[,11])^2+as.numeric(motion[,12])^2+as.numeric(motion[,13])^2), type="l", col="orange")
lines(motion$dates, sqrt(as.numeric(motion[,14])^2+as.numeric(motion[,15])^2+as.numeric(motion[,16])^2), type="l", col="yellow")

