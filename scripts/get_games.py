import sys
import re
import pandas as pd
import lxml.html


year_week_re = re.compile('year/(\d{4})/week/(\d{1,2})')
week_re = re.compile('week/(\d{1,2})')
team_score_re = re.compile('([.\w\s]+)\s(\d{1,2}),\s([.\w\s]+)\s(\d{1,2})')

def main(html):
    root = lxml.html.fromstring(html)
    
    url = root.xpath("//link[@rel='canonical']")[0].get('href')
    year_week = year_week_re.search(url)
    if year_week:
        year, week = map(int, year_week.groups())
    else:
        year, week = 2014, int(week_re.search(url).group(1))

    rows = []
    for a in root.xpath("//a[starts-with(@href, '/nfl/boxscore?gameId')]"):
        team1, score1, team2, score2 = team_score_re.search(a.text).groups()
        game_id = a.get('href').split('=')[-1]
        rows.append({
            'year': year,
            'week': week,
            'game_id': game_id,
            'team1': team1,
            'team2': team2,
            'score1': score1,
            'score2': score2,
            })
        
    return pd.DataFrame(rows)
        

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('schedule_file', nargs='+')
    parser.add_argument('--outfile', default=None)
    parser.add_argument('--no-header', default=False, action='store_true')
    args = parser.parse_args()

    dfs = []
    for fn in args.schedule_file:
        with open(fn) as f:
            dfs.append(main(f.read()))

    if not dfs:
        raise ValueError('No files')
    df = pd.concat(dfs)

    if args.outfile:
        with open(args.outfile, 'w') as f:
            df.to_csv(f, index=False, header=not args.no_header)
    else:
        df.to_csv(sys.stdout, index=False, header=not args.no_header)
