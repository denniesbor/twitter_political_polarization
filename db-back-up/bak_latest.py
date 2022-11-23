import datetime
import re

import pandas as pd
import snscrape
import snscrape.modules.twitter as sntwitter

df_handles = pd.read_csv("handles_scores.csv")


def get_time_delta(start_date: str) -> int:
    """Get the time delta of the tweets to be scraped. Initializing the database
    is set to the first Jan of 2021. A user can specify the time delta to fetch the tweets since today

    input update: int

    returns -> int
        time delta in unix
    """

    # date time
    if start_date:
        date_from = datetime.datetime.strptime(start_date, "%Y-%m-%d")
    else:
        date_from = datetime.datetime(2021, 1, 1)
    date_now = datetime.datetime.now()
    delta = (date_now - date_from).days

    time_delta1 = datetime.timedelta(days=delta)
    date_since = date_now - time_delta1

    # extract unix time
    unix = datetime.datetime.timestamp(date_since)

    return unix


def fetch_tweets(username, party, start_date=False):
    """A function that fetch tweets from a user and return as pandas DF"""

    unix = get_time_delta(start_date)

    tweet_list = []
    remove_rt = re.compile(r"^RT ")

    print(f"Fetching tweets of {username}")
    # get tweets
    for tweet_obj in sntwitter.TwitterSearchScraper(f"from:{username}").get_items():

        created_at = tweet_obj.date  # utc time tweet created
        tweet = tweet_obj.rawContent  # tweet
        unix_created = datetime.datetime.timestamp(created_at)

        if (not re.search(remove_rt, tweet)) and (unix_created >= unix):
            tweet_list.append(
                dict(
                    tweet_id=tweet_obj.id,
                    username=tweet_obj.user.username,
                    party=party,
                    tweet=tweet,
                    favorite_count=tweet_obj.likeCount,
                    retweet_count=tweet_obj.retweetCount,
                    created_at=created_at,
                    source=tweet_obj.sourceLabel,
                )
            )
        else:
            break

    if tweet_list == []:
        print("Empty Tweets")
        return
    else:

        # create dataframe
        df = pd.DataFrame(tweet_list)
        return df


def tweets(start_date: str) -> pd.DataFrame:

    """export tweets into a pandas dataframe for analysis"""

    dfs = []
    house_reps = list(zip(df_handles["Twitter Handle"], df_handles.Party))
    for user, party in house_reps[0:]:
        try:

            df = fetch_tweets(user, party, start_date=start_date)

            try:
                if df:
                    pass
            except ValueError:
                dfs.append(df)
        except snscrape.base.ScraperException:
            break

    if len(dfs) > 1:
        df = pd.concat(dfs)
        df.reset_index(inplace=True, drop=True)
        return df


# fetch tweets from the past 90 days and export to a csv file
df = tweets(start_date="2021-01-01")

df.to_csv("tweets_raw.csv", index=False)
