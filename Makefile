
## TODO(sjt): figure out how to make this aware of what week it is
data/schedules/2014:
	for i in $$(seq 1 3); do wget -O data/schedules/2014_$$i.html "http://espn.go.com/nfl/schedule/_/year/2014/week/$$i"; done
	touch data/schedules/2014

data/schedules/%:
	for i in $$(seq 1 17); do wget -O data/schedules/$*_$$i.html "http://espn.go.com/nfl/schedule/_/year/$*/week/$$i"; done
	touch data/schedules/$*

data/espn_gameids.tsv:
	grep gameId data/schedules/*.html | grep -Eo '[0-9]{5,20}' > $@

data/espn_games.csv:
	python scripts/get_games.py data/schedules/*.html > $@

data/espn_drivechart_urls.tsv: data/espn_gameids.tsv
	sed 's/\(.*\)/drivechart?gameId=\1/' $< > $@

data/drivecharts/all: data/espn_drivechart_urls.tsv
	wget --random-wait \
	--input-file=$< \
	--base="http://scores.espn.go.com/nfl/" \
	--directory-prefix=data/drivecharts \
	--no-clobber && \
	touch $@

data/espn_drives.csv: data/espn_gameids.tsv
	python scripts/get_drives.py data/drivecharts/drivechart\?gameId\=* --outfile=$@

