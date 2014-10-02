# NFL drive-level analysis

Each drive in an NFL game represents an opportunity for a team to score.  The have a few attributes:

* a starting position
* a starting time
* an offense and a defense
* an outcome:
  * Punt
  * Interception/Fumble lost
  * Turnover on downs
  * Touchdown
  * Field goal attempt
  * End of Half / Game
  

## Scraping ESPN's schedule

    $ wget -O schedule.html http://espn.go.com/nfl/schedule/_/year/2013/week/1
    $ python scripts/get_drives.py schedule.html > schedule_games.csv

We use this to get a list of ESPN gameIds for all regular season games 2002-2014.

## Scraping ESPN's drivecharts

    $ wget -O game.html http://espn.go.com/nfl/drivechart?gameId=261105003
    $ python scripts/get_drives.py game.html > game_drives.csv

There are fancier ways of automating this scraping process for whole seasons.  You can find those in the `Makefile`.

## Cleaning the data

This is mostly done in `analysis/load_data.R`.  I'm not 100% satisfied with the process yet but it passes various eyeball tests.  A few games have bad data on ESPN (not enough drives, no drives) and so they are filtered out.  Many drives themselves are listed as lineitems in the charts, but they are actually special teams plays (e.g. Kickoffs, punt returns).  These are also filtered out for now, though it may be reasonable to analyze these plays on their own.  I think average drive starting position is an interesting thing to look at next and this will depend on special teams play.

## Drive outcome analysis

I plan on using this to analyze team strength.  Eventually there will be a Bayesian model in Stan that measures each team's offensive and defensive strength and how it has evolved over time.

## Predicting game scores

Once you can forecast a distribution over drive outcomes, you need to forecast the number of drives each team will be get (and their starting positions) to get a posterior over game scores.  It should be fairly straightforward to use this approach for forecasting game outcomes, although I expect that the point distributions will be pretty high variance.
