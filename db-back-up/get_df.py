from sentiment import tweets

# fetch tweets from the past 90 days
df = tweets(90)

df.to_csv("tweets.csv", index=False)
