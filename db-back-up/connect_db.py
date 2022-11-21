# *** connect the database ***

import pandas as pd
import os

from sqlalchemy import and_
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import (
    create_engine,
    MetaData,
    DateTime,
    DECIMAL,
    Text,
    Table,
    Column,
    Integer,
    String,
)

# import db credentials
from db_cred import secr
from sentiment import get_tweets, get_house_reps

""" connect database """

# psql configuration
password = secr["password"]
db_user = secr["username"]
db = secr["dbname"]
host = secr["host"]
port = secr["port"]

# base model
Base = declarative_base()


class Twitter(Base):

    __tablename__ = "house_reps_tweets"

    id = Column(Integer, primary_key=True, autoincrement=True)
    tweet_id = Column(String(50))
    username = Column(String(50))
    party = Column(String(25))
    tweet = Column(Text)
    clean_text = Column(Text)
    favorite_count = Column(Integer)
    retweet_count = Column(Integer)
    created_at = Column(DateTime)
    source = Column(String(50))
    positive_sentiment = Column(DECIMAL(15, 4))
    neutral_sentiment = Column(DECIMAL(15, 4))
    negative_sentiment = Column(DECIMAL(15, 4))
    compound_sentiment = Column(DECIMAL(15, 4))
    sentiment_text = Column(String(50))
    social_policy = Column(String(50))
    geopolitical_policy = Column(String(50))
    policies = Column(Text)

    def __repr__(self):
        return "<Tweet(username='{}', tweet='{}', sentiment_text={})>".format(
            self.username, self.tweet, self.sentiment_text
        )


# db url
DATABASE_URI = f"postgresql+psycopg2://{db_user}:{password}@{host}:{port}/{db}"
engine = create_engine(DATABASE_URI)

# connect to db
Base.metadata.create_all(engine)
Session = sessionmaker(engine)

session = Session()


# populate the database
house_reps = get_house_reps()
for user, party in house_reps[100:]:

    df = get_tweets(user, party, engine, update=False)

    try:
        if df:
            pass
    except ValueError:
        pass
