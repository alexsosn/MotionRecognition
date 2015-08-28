## DTW ##
require("dtw")
library(dtw)
library(proxy)
demo(dtw)

load("dtw.rda")
# aw <- res.summary[99:201, 6:15]
# bw <- res.summary[202:304, 6:15]
# 
# au <- res.summary[349:451, 6:15]

plot(dtw(a$sd_acc, 
         b$sd_acc, 
         keep=TRUE, 
         open.end = T, 
         open.begin = T, 
         step=rabinerJuangStepPattern(6,"c")), 
     type="twoway", offset=-2)

plot(dtw(a$sd_acc, 
         b$sd_acc, 
         keep=TRUE), 
     type="twoway", offset=-2)

alignment <- dtw(aw$sd_acc, bw$sd_acc, keep=TRUE)
plot(alignment, type="threeway")

dis = dist(aw, au, FUN = function(x, y) { dtw(x, y, keep=TRUE)}, by_rows = F, diag = T)
heatmap(dis)

#мысль: построить матрицу расстояний по типу daisy, с метрикой dtw и посмотреть как кластеризуются типы движений.

