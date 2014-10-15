source('analysis/load_drives.R')

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
                'Touchdown' = 7,
                'Kickoff (TD)' = 7, #I guess...
                'Blocked FG (TD)' = -7,
                'Blocked Punt TD' = -7,
                'Timeout' = 0
                )
ScoredDrives<- Drives %>%
          arrange(game_id, quarter, start_time) %>%
          mutate(score_change = as.numeric(as.character(
             mapvalues(result, names(score.mapping), unlist(score.mapping))))) %>%
          mutate(score_change = ifelse(is.na(score_change), 0, score_change)) %>%
          ddply(.(game_id), transform,
          #Compute score differential? Change one team's score_changes to negative?
          score.differential = cumsum(score_change * ifelse(team==team[1], 1, -1))*ifelse(team==team[1], 1, -1))

#See how close we get to the final differential...
last_row <- ScoredDrives %>%
    ddply(.(game_id), tail, 1) %>%
    mutate(real.differential = score1 - score2,
           score.miss = real.differential - abs(score.differential))

p<- qplot(score.miss, data=last_row, geom="histogram")
p
#As expected, not perfect, but could be worse.
