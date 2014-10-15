library(arm)
library(splines)
source('analysis/estimate_score.R')

drive_secs <- function(time_str) {
return (as.numeric(as.POSIXct(strptime(time_str, format = "%M:%OS"))) - 
    as.numeric(as.POSIXct(strptime("0", format = "%S"))))
}

#Drive time model.
d <- bayesglm(drive_secs(poss_time) ~ factor(team):factor(year) +
              factor(opponent):factor(year) +
              ns(start_yard, knots = c(20,40,60,80)) +
              ns(score.differential, knots=c(-21, -14, -7, 0, 7, 14, 21)) +
              factor(quarter),
              family = gaussian,
              data = subset(ScoredDrives, res != 'End of Half' & res != 'End of Game')
              )

newdata <- with(ScoredDrives,
                expand.grid(team = unique(team),
                            opponent = unique(opponent),
                            year = 2002:2014,
                            score.differential = 0,
                            quarter = 1,
                            start_yard = 20)
                )

preds <- predict(d, newdata, type='response', se.fit = TRUE)
newdata$drive_time <- preds$fit
newdata$lcl <- preds$fit - 1.96*preds$se.fit
newdata$ucl <- preds$fit + 1.96*preds$se.fit

#2013 Offenses.

p <- newdata %>%
     filter(year == 2013) %>%
     group_by(team) %>%
     summarise(drive_time= mean(drive_time),
               lcl = mean(lcl),
               ucl = mean(ucl)) %>%
     ggplot(aes(x = reorder(team, drive_time), y = drive_time, ymin = lcl, ymax = ucl)) +
     geom_pointrange() +
     ylab('Offensive drive time with tie-score in first quarter.') +
     xlab('Team') +
     coord_flip() +
     theme_bw()
p

#2013 Defenses
p <- newdata %>%
     filter(year == 2013) %>%
     group_by(opponent) %>%
     summarise(drive_time= mean(drive_time),
               lcl = mean(lcl),
               ucl = mean(ucl)) %>%
     ggplot(aes(x = reorder(opponent, drive_time), y = drive_time, ymin = lcl, ymax = ucl)) +
     geom_pointrange() +
     ylab('Defensive drive time with tie-score in first quarter.') +
     xlab('Team') +
     coord_flip() +
     theme_bw()
p

#Describe drive times.
drive.time.model<- bayesglm(drive_secs(poss_time) ~
                            factor(year)*ns(start_yard, knots = c(20,40,60,80)),
              family = gaussian,
              data = subset(ScoredDrives, res != 'End of Half' & res != 'End of Game')
              )

drive.data <- expand.grid(year=2002:2013, start_yard=1:100)
preds <- predict(drive.time.model, drive.data, type='response', se.fit=TRUE)
drive.data$drive_time <- preds$fit
drive.data$lcl <- preds$fit - 1.96*preds$se.fit
drive.data$ucl <- preds$fit + 1.96*preds$se.fit

p <- ggplot(aes(x = start_yard, y = drive_time, ymin = lcl, ymax = ucl, colour = factor(year)),
            data = drive.data) +
    geom_line() +
    theme_bw() +
    xlab('Drive Starting Position') +
    ylab('Drive time')
p


#Describe drive times by score differential
drive.time.model<- bayesglm(drive_secs(poss_time) ~
                            factor(year)*ns(score.differential,
                                            knots=c(-21, -14, -7, 0, 7, 14, 21)),
              family = gaussian,
              data = subset(ScoredDrives, res != 'End of Half' & res != 'End of Game')
              )

drive.data <- expand.grid(year=2002:2013, score.differential=-30:30)
preds <- predict(drive.time.model, drive.data, type='response', se.fit=TRUE)
drive.data$drive_time <- preds$fit
drive.data$lcl <- preds$fit - 1.96*preds$se.fit
drive.data$ucl <- preds$fit + 1.96*preds$se.fit

p <- drive.data %>%
     group_by(score.differential, year) %>%
     summarise(drive_time = mean(drive_time),
               lcl = mean(lcl),
               ucl = mean(ucl)) %>%
     ggplot(aes(x = score.differential, y = drive_time, ymin = lcl, ymax = ucl, colour = factor(year)),
            ) +
    geom_line() +
    theme_bw() +
    xlab('Score differential') +
    ylab('Drive time')
p
