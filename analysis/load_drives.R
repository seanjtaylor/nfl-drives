library(plyr)
library(dplyr)
library(data.table)
library(ggplot2)
library(reshape2)

## lots of data quality stuff here
## 1. rename a bunch of result names
## 2. plot distributions of stuff to do some sanity checking
## 3. Make sure two teams for each game

Games <- fread('data/espn_games.csv')

Drives <- read.csv('data/espn_drives.csv') %>%
  mutate(gametime = as.POSIXct(paste('2014-01-01 00:', gametime, sep=''), tz='UTC')) %>%
  inner_join(Games)

## before re-mapping results
p <- Drives %>%
  group_by(result) %>%
  summarise(n = n()) %>%
  ungroup %>%
  arrange(-n) %>%
  mutate(cum.n = cumsum(n)) %>%
  head(30) %>%
  ggplot(aes(x = reorder(result, n), y = n)) +
  geom_bar(stat = 'identity') +
  xlab('Drive Result') +
  ylab('Count') + 
  coord_flip()
p
ggsave('figures/results_before_renaming.png', p, height = 6, width = 6)

mapping <- list('TD' = 'Touchdown',
                'Rushing TD' = 'Touchdown',
                'Passing TD' = 'Touchdown',
                'RUSH Touchdown' = 'Touchdown',
                'PASSRECEPTION Touchdown' = 'Touchdown',
                'Field Goal' = 'Field Goal Attempt',
                'Made FG' = 'Field Goal Attempt',
                'Field Goal Good' = 'Field Goal Attempt',
                'Missed FG' = 'Field Goal Attempt',
                'Missed Field Goal' = 'Field Goal Attempt',
                'Blocked FG' = 'Field Goal Attempt',
                'FIELDGOAL Made field goal' = 'Field Goal Attempt',
                'FIELDGOAL' = 'Field Goal Attempt',
                'blocked Kick' = 'Field Goal Attempt',
                'Turnover on Downs' = 'Downs',
                'Pass Complete' = 'Downs',
                'Pass Completion' = 'Downs',
                'Incomplete' = 'Downs',
                'Incomplete Pass' = 'Downs',
                'Fumble Recovery (Own)' = 'Downs',
                'Sack' = 'Downs',
                'Rush' = 'Downs',
                'Pass' = 'Downs',
                'Poss. on downs' = 'Downs',
                'RUSH' = 'Downs',
                'Blocked Punt, Downs' = 'Downs',
                'Interception TD' = 'Interception',
                'Intercepted Pass' = 'Interception',
                'Pass Interception' = 'Interception',
                'Fumble Recovery (Opponent)' = 'Fumble',
                'Fumble Ret. TD' = 'Fumble',
                'Fumble TD' = 'Fumble',
                'Blocked Punt' = 'Punt',
                'PUNT' = 'Punt',
                'End of 1st Half' = 'End of Half',
                'Fumble, Safety' = 'Safety'
                )

score.mapping <- list('TD' = 7,
                'Rushing TD' = 7,
                'Passing TD' = 7,
                'RUSH Touchdown' = 7,
                'PASSRECEPTION Touchdown' = 7,
                'Field Goal' = 3,
                'Made FG' = 3,
                'Field Goal Good' = 3,
                'Missed FG' = 0,
                'Missed Field Goal' = 0,
                'Blocked FG' = 0,
                'FIELDGOAL Made field goal' = 3,
                'FIELDGOAL' = 3,
                'blocked Kick' = 0,
                'Turnover on Downs' = 0,
                'Pass Complete' = 0,
                'Pass Completion' = 0,
                'Incomplete' = 0,
                'Incomplete Pass' = 0,
                'Fumble Recovery (Own)' = 0,
                'Sack' = 0,
                'Rush' = 0,
                'Pass' = 0,
                'Poss. on downs' = 0,
                'RUSH' = 0,
                'Blocked Punt, Downs' = 0,
                'Interception TD' = -7,
                'Intercepted Pass' = 0,
                'Pass Interception' = 0,
                'Fumble Recovery (Opponent)' = 0,
                'Fumble Ret. TD' = -7,
                'Fumble TD' = 7,
                'Blocked Punt' = 0,
                'PUNT' = 0,
                'End of 1st Half' = 0,
                'Fumble, Safety' = -2,
                'Punt' = 0,
                'Interception' = 0,
                'Fumble' = 0,
                'Kickoff' = 0,
                'Kickoff (TD)' = 7, #I guess...
                'Blocked FG (TD)' = -7,
                'Blocked Punt TD' = -7,
                'Timeout' = 0
                )
Drives <- Drives %>%
  mutate(res = mapvalues(result, names(mapping), unlist(mapping)))

## results after renaming
p <- Drives %>%
  group_by(res) %>%
  summarise(n = n()) %>%
  ungroup %>%
  arrange(-n) %>%
  mutate(cum.n = cumsum(n)) %>%
  head(30) %>%
  ggplot(aes(x = reorder(res, n), y = n)) +
  geom_bar(stat = 'identity') +
  xlab('Drive Result') +
  ylab('Count') + 
  coord_flip()
p
ggsave('figures/results_after_renaming.png', p, height = 6, width = 6)

## check the result by year/week to see if data looks consistent over time
normal.results <- c('Punt', 'Touchdown', 'Field Goal Attempt', 'Interception', 'Downs', 'Fumble', 'End of Half', 'End of Game', 'Safety')

p <- Drives %>%
  filter(res %in% normal.results) %>%
  group_by(year, week) %>%
  summarise(num_games = length(unique(game_id))) %>%
  ggplot(aes(x = week, y = num_games)) +
  facet_grid(. ~ year, scales = 'free_y') +
  ylab('Number of Games') +
  geom_line()
p
ggsave('figures/num_games_year_week.png', p, height = 12, width = 12)

p <- Drives %>%
  filter(res %in% normal.results) %>%
  group_by(year, week) %>%
  summarise(num_drives = n()) %>%
  ggplot(aes(x = week, y = num_drives)) +
  facet_grid(. ~ year, scales = 'free_y') +
  ylab('Number of Drives') +
  geom_line()
p
ggsave('figures/num_drives_year_week.png', p, height = 12, width = 12)

## check games to see if there are any weird ones

## ones with only one team/opponent
Drives %>%
  group_by(game_id) %>%
  summarise(n.teams = length(unique(team)),
            n.opps = length(unique(opponent))) %>%
  filter(n.opps != 2 | n.teams != 2) %>%
  head(20)

## ones with very small/large number of drives
p <- Drives %>%
  filter(res %in% normal.results) %>%
  group_by(game_id) %>%
  summarise(num_drives = n()) %>%
  ggplot(aes(x = num_drives)) +
  geom_histogram(binwidth = 1)
p

ggsave('figures/num_drives_by_game_before.png', p, height = 6, width = 6)

Drives <- Drives %>%
  group_by(game_id) %>%
  mutate(num_drives = n()) %>%
  filter(num_drives > 13, num_drives < 40) %>%
  select(-num_drives) %>%
  ungroup

p <- Drives %>%
  filter(res %in% normal.results) %>%
  group_by(game_id) %>%
  summarise(num_drives = n()) %>%
  filter(num_drives > 13, num_drives < 40) %>%
  ggplot(aes(x = num_drives)) +
  geom_histogram(binwidth = 1)
p

ggsave('figures/num_drives_by_game_after.png', p, height = 6, width = 6)

Drives <- Drives %>% filter(res %in% normal.results)

  
