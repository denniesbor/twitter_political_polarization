import os
import re
import json
import datetime
from datetime import date
from contextlib import contextmanager
import contractions

import snscrape.modules.twitter as sntwitter
import pandas as pd

import nltk
from nltk.corpus import stopwords

nltk.download("stopwords")
from nltk.sentiment.vader import SentimentIntensityAnalyzer as SIA

sid = SIA()
# stopwords
stopwords_set = set(stopwords.words("english"))

# update stopwords set
stopwords_set.update(
    ["s", "will", "amp", "must", "rt", "american", "americans", "re", "000"]
)

# link us reps website
url = "https://pressgallery.house.gov/member-data/members-official-twitter-handles"

# Opening JSON file
with open("../notebooks/data.json") as json_file:
    categories = json.load(json_file)


def dataframe_tosql(df, engine):
    """Function that establishes connection to a mysql database
    and save the data frame
    """

    print("beginning tweets export to a sql server")
    with engine.connect().execution_options(autocommit=True) as conn:
        df.to_sql("house_reps_tweets", con=conn, if_exists="append", index=False)

    print("Tweets exported to a sql server")


def get_policy_cat(text):
    """This function searches through a tweet text and categorizes it into
    their respective categories, e.g., geo-political or social, and further
    break down into sub-categories, e.g., climate change, etc.
    """

    social_policy = ""
    geopolitical_policy = ""
    policies = ""
    policy_cat = ""

    for policy_type in categories:

        for policy in categories[policy_type]:
            if policy != "All":
                search = "|".join([f"{p} " for p in categories[policy_type][policy]])
                regexp = re.search(r"%s" % search, text, re.I)

                if regexp:
                    policies += policy + "|"

                    if policy_type in policy_cat:
                        pass
                    else:
                        policy_cat += policy_type + " "
                        if policy_type == "Social Policies":
                            social_policy += policy_type
                        if policy_type == "Geo Political Policies":
                            geopolitical_policy += policy_type
            else:
                pass

    return pd.Series([social_policy, geopolitical_policy, str(policies.split("|"))])


def get_house_reps():

    """A function which scrapes US representatives and their Twitter handles

    ------------
    attributes

    return: list
      list of tuples of each house rep and the party
    ------------
    """

    # read the housereps and pass into a dataframe
    print("***Fetching house reps ***")
    dfs = pd.read_html(url)
    print("***House reps response received***")
    house_reps = dfs[0]

    # make the first row as columns
    house_reps.columns = house_reps.iloc[1]

    df = house_reps.drop(index=0, inplace=False)[["Twitter Handle", "Party"]]
    df["Twitter Handle"] = df["Twitter Handle"].str.replace("@", "")

    # create list of tuples from the columns of dataframes
    house_rep_lists = list(zip(df["Twitter Handle"], df.Party))

    return house_rep_lists


def contractors(text):
    """Cleaning the texts, non-alphanumeric letters are removed
    including those in shortened words such as can't, won't, etc.
    This function expands these words.
    """

    # creating an empty list
    expanded_words = []

    for word in text.split():
        # using contractions.fix to expand the shortened words
        expanded_words.append(contractions.fix(word))

    expanded_text = " ".join(expanded_words)
    return expanded_text


def clean_tweets(tweet: str):
    """This function cleans the tweets
    Attrs
    ---------
    input: str
    tweet
    Returns
    ---------
    output: str
    clean tweet
    """

    tweet = contractors(tweet)
    tweet = tweet.lower()
    tweet = re.sub("@[^\s]+", "", tweet)  # remove twitter handlers
    # tweet = re.sub(r'\B#\S+','',tweet)  # remove hashtags
    tweet = re.sub(r"http\S+", "", tweet)  # Remove URLS
    tweet = re.sub(
        r"\s+", " ", tweet, flags=re.I
    )  # substitute multiple spaces with single space
    tweet = " ".join(re.findall(r"\w+", tweet))  # remove all the special characters
    tweet = re.sub(r"(^| ).(( ).)*( |$)", " ", tweet)  # remove all single characters

    return tweet


def compute_sentiments(df):

    """Function which computes the sentiments of a dataframe texts."""
    df["sentiments"] = df["clean_text"].apply(
        lambda x: sid.polarity_scores(" ".join(re.findall(r"\w+", x.lower())))
    )

    # extract scores of sentiments. 0.00001 added incase of a score of 0
    df["positive_sentiment"] = df["sentiments"].apply(
        lambda x: x["pos"] + 1 * (10**-6)
    )
    df["neutral_sentiment"] = df["sentiments"].apply(
        lambda x: x["neu"] + 1 * (10**-6)
    )
    df["negative_sentiment"] = df["sentiments"].apply(
        lambda x: x["neg"] + 1 * (10**-6)
    )
    df["compound_sentiment"] = df["sentiments"].apply(
        lambda x: x["compound"] + 1 * (10**-6)
    )
    df["sentiment_text"] = df["compound_sentiment"].apply(
        lambda x: "positive" if x > 0.05 else ("negative" if x < -0.05 else "neutral")
    )
    df.drop(columns=["sentiments"], inplace=True)

    print("Finished computing sentiment analysis \n")

    return df


def get_time_delta(update: int) -> int:
    """Get the time delta of the tweets to be scraped. Initializing the database
    is set to the first Jan of 2021. A user can specify the time delta to fetch the tweets since today

    input update: int

    returns -> int
        time delta in unix
    """

    # date time
    date_from = datetime.datetime(2021, 1, 1)
    date_now = datetime.datetime.now()
    delta = (date_now - date_from).days

    if update:
        delta = update

    time_delta1 = datetime.timedelta(days=delta)
    date_since = date_now - time_delta1

    # extract unix time
    unix = datetime.datetime.timestamp(date_since)

    return unix


def fetch_tweets(username, party, update=False):
    """A function that fetch tweets from a user and return as pandas DF"""

    unix = get_time_delta(update)

    tweet_list = []
    compile = re.compile(r"^RT ")

    print(f"Fetching tweets of {username}")
    # get tweets
    for tweet_obj in sntwitter.TwitterSearchScraper(f"from:{username}").get_items():

        created_at = tweet_obj.date  # utc time tweet created
        tweet = tweet_obj.rawContent  # tweet
        unix_created = datetime.datetime.timestamp(created_at)

        if (not re.search(compile, tweet)) and (unix_created >= unix):
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
        df["clean_text"] = df["tweet"].apply(clean_tweets)
        print("finished cleaning tweets")

        df[["social_policy", "geopolitical_policy", "policies"]] = df.clean_text.apply(
            get_policy_cat
        )

        # drop empty policies
        df = df[df["policies"].map(lambda text: len(text)) > 1]
        df = compute_sentiments(df)

        return df


def tweets(update_time: int, engine=False) -> pd.DataFrame:

    """export tweets into a pandas dataframe for analysis"""

    dfs = []
    house_reps = get_house_reps()
    for user, party in house_reps[0:]:

        df = fetch_tweets(user, party, update=update_time)

        try:
            if df:
                pass
        except ValueError:
            dfs.append(df)
    if len(dfs) > 1:
        df = pd.concat(dfs)
        df.reset_index(inplace=True, drop=True)

        if engine:
            dataframe_tosql(df, engine)

        return df
