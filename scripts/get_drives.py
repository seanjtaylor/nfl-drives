import sys
from datetime import timedelta
import pandas as pd
from collections import Counter
import lxml.html

def main(html):
    root = lxml.html.fromstring(html)

    rows = [None, None]
    counts = Counter()
    for i, table in enumerate(root.xpath("//table[@class='mod-data']/tbody")):
        rows[i] = [list(tr.itertext()) for tr in table.getchildren()]

        # assume most drives start in team's territory
        # the ' 0' is a kickoff which is weird part of data that messes up this
        # heuristic
        for r in rows[i]:
            if ' 0' in r[3]:
                continue
            team = r[3].split()[0]
            counts[(team, i)] += 1


    # assigns one team to each table based on starting position
    # (I'm too lazy to actually parse this out)
    teams = [None, None]
    for (team, i), count in counts.most_common(4):
        if teams[i] is None and team != teams[1 - i]:
            teams[i] = team

    assert all(teams)

    for row in rows[0]:
        row.extend(teams)
    for row in rows[1]:
        row.extend(reversed(teams))


    df = pd.DataFrame(
        rows[0] + rows[1],
        columns='start_time quarter poss_time start_string num_plays num_yards result team opponent'.split()
        )

    return clean_df(df)

def gametime(df):
    mins, secs = df['start_time'].split(':')

    in_qrt = timedelta(minutes=15) - timedelta(minutes=int(mins), 
                                               seconds=int(secs))
    qrt = (df['quarter'] - 1) * timedelta(minutes=15)

    return in_qrt + qrt

def start_yard(df):
    if df['start_string'] == '50':
        return 50
    team, yard = df['start_string'].split()
    yard = int(yard)
    if team == df['team']:
        return yard
    else:
        return 100 - yard

def clean_df(df):
    df['quarter'] = df['quarter'].apply(lambda x: 5 if x == 'OT' else int(x))
    df['gametime'] = df.apply(gametime, 1)
    df['start_yard'] = df.apply(start_yard, 1)
    return df

if __name__ == '__main__':
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('game_files', nargs='+')
    parser.add_argument('--outfile', default=None)
    args = parser.parse_args()

    for i, fn in enumerate(args.game_files):
        sys.stderr.write('processing {0}\n'.format(fn))
        with open(fn) as f:
            html = f.read()
            if 'Drive chart currently unavailable.' in html:
                continue

            df = main(html)
            df['game_id'] = fn.split('=')[-1]

            if args.outfile:
                with open(args.outfile, 'a') as outf:
                    df.to_csv(outf, index=False, header=(i == 0),
                              encoding='utf-8')
            else:
                df.to_csv(sys.stdout, index=False, header=(i == 0), 
                          encoding='utf-8')
            
