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
with open("../data.json") as json_file:
    available_options = json.load(json_file)


def dataframe_tosql(df, engine):
    """Function that establishes connection to a mysql database
    and save the data frame
    """

    print("beginning tweets export to a sql server")
    with engine.connect().execution_options(autocommit=True) as conn:
        df.to_sql("house_reps_tweets", con=conn, if_exists="append", index=False)

    print("Tweets exported to a sql server")


def get_policy_cat(text):

    # extracts the policy and policy categories of the texts

    social_policy = ""
    geopolitical_policy = ""
    policies = ""
    policy_cat = ""

    for policy_type in available_options:

        for policy in available_options[policy_type]:
            if policy != "All":
                search = "|".join(available_options[policy_type][policy])
                regexp = re.search(r"%s" % search, text, re.I)

                if regexp:
                    policies += policy + " "

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

    return social_policy, geopolitical_policy, policies


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
    """' while cleaning the texts, the non-alphanumeric letters are removed. This includes those in
    the shortened words such as can't, n't, etc. This functions expands those words as they affect the
    overall sentiment values.
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
    tweet = re.sub("@[^\s]+", "", tweet)  # Remove twitter handlers
    # tweet = re.sub(r'\B#\S+','',tweet)   #remove hashtags
    tweet = re.sub(r"http\S+", "", tweet)  # Remove URLS
    tweet = re.sub(
        r"\s+", " ", tweet, flags=re.I
    )  # Substituting multiple spaces with single space
    tweet = " ".join(re.findall(r"\w+", tweet))  # Remove all the special characters
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


def get_time_delta(update):
    """Get the time delta of the tweets to be scraped. Initializing the database
    is set to first jan of 2020, and regular updates as one day
    """

    # date time
    date_from = datetime.datetime(2021, 1, 1)
    date_now = datetime.datetime.now()
    delta = (date_now - date_from).days

    if update:
        delta = 1

    time_delta1 = datetime.timedelta(days=delta)
    date_since = date_now - time_delta1

    # extract unix time
    unix = datetime.datetime.timestamp(date_since)

    return unix


def get_tweets(username, party, engine, update=True):

    """A function that fetch tweets from a user and return as pandas DF"""

    unix = get_time_delta(update)

    tweet_list = []
    compile = re.compile(r"^RT ")

    print(f"Fetching tweets of {username}")
    try:
        # get tweets
        for tweet_obj in sntwitter.TwitterSearchScraper(f"from:{username}").get_items():

            created_at = tweet_obj.date  # utc time tweet created
            unix_created = datetime.datetime.timestamp(created_at)

            if unix_created >= unix:

                tweet = tweet_obj.rawContent  # tweet
                clean_text = clean_tweets(tweet)
                if engine:
                    social_policy, geopolitical_policy, policies = get_policy_cat(
                        clean_text
                    )
                else:
                    social_policy, geopolitical_policy, policies = (None, None, None)
                # tweet attrs
                if (not re.search(compile, tweet)) and (len(clean_text.strip()) > 2):

                    tweet_list.append(
                        dict(
                            tweet_id=tweet_obj.id,
                            username=tweet_obj.user.username,
                            party=party,
                            tweet=tweet,
                            clean_text=clean_text,
                            favorite_count=tweet_obj.likeCount,
                            retweet_count=tweet_obj.retweetCount,
                            created_at=created_at,
                            source=tweet_obj.sourceLabel,
                            social_policy=social_policy,
                            geopolitical_policy=geopolitical_policy,
                            policies=policies,
                        )
                    )
            else:
                break

        if tweet_list == []:
            print("Empty Tweets")
            return None
        else:
            # create dataframe
            df = pd.DataFrame(tweet_list)

            if engine:
                df = compute_sentiments(df)
                dataframe_tosql(df, engine)
            return df

    except ValueError:
        print("Error in fetching tweets")
        return None
