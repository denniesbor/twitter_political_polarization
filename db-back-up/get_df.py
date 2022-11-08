import pandas as pd
import os

from sentiment import get_tweets, get_house_reps

# populate the database
dfs = []
house_reps = get_house_reps()
for user, party in house_reps[:]:
    
    df = get_tweets(user, party, engine=None, update=False)
    
    try:
        if df:
            pass
    except ValueError:
        dfs.append(df)
    
    
df = pd.concat(dfs)
df.to_csv('tweets.csv', index=False)