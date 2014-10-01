library(arm)
library(splines)

source('analysis/load_drives.R')

td.model <- bayesglm(I(res == 'Touchdown') ~
         factor(year)*ns(start_yard, knots = c(20,40,60,80)),
         family = binomial,
         data = Drives)


fg.model <- update(td.model, I(res == 'Field Goal Attempt') ~ .)

pt.model <- update(td.model, I(res == 'Punt') ~ .)

it.model <- update(td.model, I(res == 'Interception') ~ .)

td.data <- expand.grid(year = 2002:2013,start_yard = 1:100)
preds <- predict(td.model, td.data, type = 'response', se.fit = TRUE)
td.data$outcome <- 'Touchdown'
td.data$prob <- preds$fit
td.data$lcl <- preds$fit - 1.96*preds$se.fit
td.data$ucl <- preds$fit + 1.96*preds$se.fit


fg.data <- expand.grid(year = 2002:2013,start_yard = 1:100)
preds <- predict(fg.model, fg.data, type = 'response', se.fit = TRUE)
fg.data$outcome <- 'Field Goal Attempt'
fg.data$prob <- preds$fit
fg.data$lcl <- preds$fit - 1.96*preds$se.fit
fg.data$ucl <- preds$fit + 1.96*preds$se.fit

pt.data <- expand.grid(year = 2002:2013,start_yard = 1:100)
preds <- predict(pt.model, pt.data, type = 'response', se.fit = TRUE)
pt.data$outcome <- 'Punt'
pt.data$prob <- preds$fit
pt.data$lcl <- preds$fit - 1.96*preds$se.fit
pt.data$ucl <- preds$fit + 1.96*preds$se.fit

it.data <- expand.grid(year = 2002:2013,start_yard = 1:100)
preds <- predict(it.model, pt.data, type = 'response', se.fit = TRUE)
it.data$outcome <- 'Interception'
it.data$prob <- preds$fit
it.data$lcl <- preds$fit - 1.96*preds$se.fit
it.data$ucl <- preds$fit + 1.96*preds$se.fit

p <- rbind(td.data, fg.data, pt.data, it.data) %>%
  ggplot(aes(x = start_yard, y = prob, ymin = lcl, ymax = ucl, colour = factor(year))) +
  facet_grid(outcome ~ .) +
  geom_line() +
  theme_bw() +
  xlab('Drive Starting Position') +
  ylab('Probability of Drive Result')
p
ggsave('figures/drive_result_by_starting_position.png', p, height = 6, width = 6)
