
library(arm)
library(splines)
source('analysis/load_drives.R')

## offense and defense variables for each year
m <- bayesglm(I(res == 'Touchdown') ~
         factor(team):factor(year) +
         factor(opponent):factor(year) +
         ns(start_yard, knots = c(20, 40, 60, 80)),
         family = binomial,
         data = Drives)

newdata <- with(Drives,
                expand.grid(team = unique(team),
                            opponent = unique(opponent),
                            year = 2002:2014,
                            start_yard = 20))

preds <- predict(m, newdata, type = 'response', se.fit = TRUE)
newdata$prob <- preds$fit
newdata$lcl <- preds$fit - 1.96*preds$se.fit
newdata$ucl <- preds$fit + 1.96*preds$se.fit

## 2013 offenses
p <- newdata %>%
  filter(year == 2013) %>%
  group_by(team) %>%
  summarise(prob = mean(prob),
            lcl = mean(lcl),
            ucl = mean(ucl)) %>%
  ggplot(aes(x = reorder(team, prob), y = prob, ymin = lcl, ymax = ucl)) +
  geom_pointrange() +
  ylab('Prob of scoring a TD from the 20') +
  xlab('Team') +
  coord_flip() +
  theme_bw()
p
ggsave('figures/prob_td_offense_2013.png', p, height = 6, width = 6)


## 2013 defenses
p <- newdata %>%
  filter(year == 2013) %>%
  group_by(opponent) %>%
  summarise(prob = mean(prob),
            lcl = mean(lcl),
            ucl = mean(ucl)) %>%
  ggplot(aes(x = reorder(opponent, -prob), y = prob, ymin = lcl, ymax = ucl)) +
  geom_pointrange() +
  ylab('Prob of allowing a TD from the 20') +
  xlab('Team') +
  coord_flip() +
  theme_bw()
p
ggsave('figures/prob_td_defense_2013.png', p, height = 6, width = 6)
