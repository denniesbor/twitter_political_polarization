import pandas as pd
import os

from sqlalchemy import and_
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import create_engine, MetaData, DateTime,\
    DECIMAL, Text,\
        Table, Column,\
            Integer, String

from apps.db_cred import secr

''' connect database '''

# psql configuration
password=secr['password']
db_user=secr['username']
db=secr['dbname']
host=secr['host']
port=secr["port"]

# base model
Base = declarative_base()

class Twitter(Base):
    
    __tablename__ = 'house_reps_tweets'
    
    id = Column(Integer, primary_key = True, autoincrement = True)
    tweet_id = Column(String(50))
    username = Column(String(50))
    party = Column(String(25))
    tweet = Column(Text)
    clean_text = Column(Text) 
    favorite_count = Column(Integer) 
    retweet_count = Column(Integer)
    created_at = Column(DateTime) 
    source = Column(String(50)) 
    positive_sentiment = Column(DECIMAL(15,4))
    neutral_sentiment = Column(DECIMAL(15,4))
    negative_sentiment = Column(DECIMAL(15,4)) 
    compound_sentiment = Column(DECIMAL(15,4))
    sentiment_text = Column(String(50))
    social_policy=Column(String(50))
    geopolitical_policy=Column(String(50))
    policies=Column(Text)
    
    def __repr__(self):
        return "<Tweet(username='{}', tweet='{}', sentiment_text={})>"\
                .format(self.username, self.tweet,self.sentiment_text)
    
# db url
DATABASE_URI = f'postgresql+psycopg2://{db_user}:{password}@{host}:{port}/{db}'
engine = create_engine(DATABASE_URI)

# connect to db
Base.metadata.create_all(engine)
Session = sessionmaker(engine)

session = Session()


def query_db(category_table_column, date_value):
    '''
        This function queries the database based on the user input start date 
        and the policy category.
        
        -------------
        input (str, datetime)
        return (queryset)
    '''

    if(category_table_column == "All"):
        result = session.query(Twitter) \
                    .with_entities(
                    Twitter.party, 
                    Twitter.tweet,
                    Twitter.clean_text,
                    Twitter.created_at,
                    Twitter.compound_sentiment,
                    Twitter.sentiment_text,
                    Twitter.social_policy,
                    Twitter.geopolitical_policy,
                    Twitter.policies) \
                    .filter(Twitter.created_at > date_value).all()
    
    if(category_table_column == "Geo Political Policies"):
        result = session.query(Twitter) \
                .with_entities(
                Twitter.party, 
                Twitter.tweet,
                Twitter.clean_text,
                Twitter.created_at,
                Twitter.compound_sentiment,
                Twitter.sentiment_text,
                Twitter.social_policy,
                Twitter.geopolitical_policy,
                Twitter.policies) \
                  .filter(and_(Twitter.created_at > date_value,
                                Twitter.geopolitical_policy ==  'Geo Political Policies')).all()
    
    if(category_table_column == "Social Policies"):
        result = session.query(Twitter) \
                .with_entities(
                Twitter.party, 
                Twitter.tweet,
                Twitter.clean_text,
                Twitter.created_at,
                Twitter.compound_sentiment,
                Twitter.sentiment_text,
                Twitter.social_policy,
                Twitter.geopolitical_policy,
                Twitter.policies) \
                .filter(and_(Twitter.created_at > date_value,
                        Twitter.social_policy ==  'Social Policies')).all()
        
    return result

def political_category(party, df):
    """
    input str: political category(dems or reps), df
    
    returns -> df
    """
    
    df['party'] = df['party'].replace(['R','D',None], ['Republicans', 'Democrats','Other'], regex = True)
    
    if (party == "all"):
        return df
    else:
        df = df[df.party==party]
        return df

def policy_category(policy, df):
    '''This function will filter the pandas dataframe 
    on policy using regular string matching patterns.

    input: str (policy), df

    returns -> df
    '''
    if policy.lower() == "all":
        return df
    else:
        df = df[df.policies.str.contains(r'%s' %policy, case=False)]
    
    return df

def sentiment_df(sentiment, df):
    '''
     input: str (sentiment type), df
     
     returns -> df
    '''
    
    if sentiment == 'All':
        return df
    else:
        df = df[df['sentiment_text']==sentiment.lower()]       
        return df
    
def get_df(controls):
    
    '''This functions queries the database and extract
    tweets based on the web ui choices
    
    input dict: options
    
    returns -> df
    '''
    

    # result of the db query
    result = query_db(controls["policy_category"], controls["date_value"])

    if result is None:
        raise Exception('The query returned is None')
    
    else:
        # export query to a pandas dataframe
        df = pd.DataFrame(result)

    # get political category
    df = political_category(controls["party"], df)

    # get sentiment values
    df = sentiment_df(controls["sentiment"], df)

    # get the policy df
    df = policy_category(controls["selected_policy"], df)
    
    # clean df before export
    df = df[df.clean_text != '']
    df.rename(columns = {'clean_text':'text'}, inplace = True)
    
    return df
    
    
