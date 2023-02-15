"""

Graphs to be rendered to the user

"""

import re
import collections

import pandas as pd

# Viz Pkgs
import plotly.express as px
import matplotlib.pyplot as plt
import matplotlib
from wordcloud import WordCloud, STOPWORDS, ImageColorGenerator

matplotlib.use("Agg")


"""
 stop words
"""
# stopwords
stopwords_set = set(STOPWORDS)

# update stopwords set
stopwords_set.update(
    ["s", "will", "amp", "must", "rt", "american", "americans", "re", "000"]
)

"""
 plotly arguments
"""

plotly_args = dict(
    legend=dict(yanchor="top", y=0.99, xanchor="left", x=0.8),
    margin={"r": 1, "t": 1, "l": 1, "b": 1},
)

"""
 charts
"""


def chart_type_plot(chart_type, df, template):
    """This function plots a specified chart of Histogram, bar chart,
    or Scatter plot and returns a plotly figure object

    params
    -------------
    input: str, pandas.Df
    chart type, pandas pandas dataframe
    returns
    ---------
    output -> plotly object
    a plotly figure object
    """

    args = dict(color="party", height=300, template=template, log_y=True)

    if chart_type == "Histogram":
        fig = px.histogram(
            df,
            x="compound_sentiment",
            histnorm="density",
            nbins=20,
            text_auto=".0f",
            **args
        )

    elif chart_type == "Bar":
        fig = px.histogram(
            df, x="sentiment_text", barmode="group", text_auto=".0f", **args
        )

    elif chart_type == "Scatter":
        df["compound_sentiment"] = df["compound_sentiment"].round(decimals=3)
        df = (
            df[["compound_sentiment", "party", "tweet_id"]]
            .groupby(["compound_sentiment", "party"])
            .count()
        )
        df = df.reset_index()
        fig = px.scatter(
            df,
            x="compound_sentiment",
            y="tweet_id",
            labels={
                "compound_sentiment": "Sentiment Label (-1 - 1)",
                "tweet_id": "Value Count",
            },
            **args
        )

    fig.update_layout(**plotly_args)

    return fig


# plot tweet sentiment timeseries
def get_time_sentiments(df, template):

    """This function calculates the volume of neutral, negative,
    and positive tweets since the start of the year 2022

    parameters
    -------------
    input: pandas.DataFrame
      pandas dataframe object

    return: object
      plotly object

    """

    df["created_at"] = pd.to_datetime(df.created_at)
    df = df[df["created_at"] >= "2022-01-01"]
    df = df.resample("D", on="created_at")["sentiment_text"].value_counts().unstack(1)
    df.reset_index(inplace=True)
    df = df.melt("created_at", var_name="sentiment", value_name="vals")
    fig = px.line(
        df,
        x="created_at",
        y="vals",
        color="sentiment",
        height=300,
        labels={"created_at": "Date", "vals": "Count"},
        template=template,
    )
    fig.update_layout(**plotly_args)

    return fig


# plot word cloud
def plot_wc(
    df,
    mask=None,
    max_words=200,
    max_font_size=100,
    figure_size=(8, 12),
    color="white",
    title=None,
    title_size=40,
    image_color=False,
):

    """This function extracts tweets from a dataframe, split into individual terms
    and plots the most occuring words. Stopwords are excluded

    params
    --------plot_wc
    input: dict:pd.DataFrame
      pandas dataframe
    returns
    ---------
    output -> plt.Figure
      matplotlib figure object
    """

    fig = plt.figure(figsize=figure_size, dpi=300)
    text = " ".join(tweet for tweet in df["text"])
    wordcloud = WordCloud(
        background_color=color,
        stopwords=stopwords_set,
        random_state=42,
        width=400,
        height=500,
        mask=mask,
    )
    wordcloud.generate(str(text))
    if image_color:
        image_colors = ImageColorGenerator(mask)
        plt.imshow(wordcloud.recolor(color_func=image_colors), interpolation="bilinear")
        plt.title(title, fontdict={"size": title_size, "verticalalignment": "bottom"})
    else:
        plt.imshow(wordcloud, interpolation="bilinear")
    plt.axis("off")

    return fig


def clean_tweets(tweet: str):

    """This function cleans the tweets

    Attrs
    ---------
    input: str
    tweet
    Returns
    ---------
    output: list
    clean tweet
    """

    tweet = re.sub(r"\s+", " ", tweet, flags=re.I)
    tweet_list = [
        word for word in re.findall(r"\w+", tweet) if word not in stopwords_set
    ]

    return tweet_list


# wc list
def get_wc_words(df, max_word_count=70):

    # returns top appearing words in the dataset

    df["text"] = df["text"].apply(clean_tweets)
    all_words = [
        item for sublist in [word for word in list(df.text)] for item in sublist
    ]

    return collections.Counter(all_words).most_common()[:70]


# tree map
def tree_map(common_words, template):
    """function which takes a dataframe of tweets and returns tree map
        as a Plotly object

    params:
    -----------
    input: pandas dataframe
        df

    returns
    ----------
    output: obj
        plotly figure
    """

    fig = px.treemap(
        pd.DataFrame(common_words, columns=["common words", "values"]),
        path=["common words"],
        values="values",
        template=template,
        height=250,
    )

    fig.update_layout(**plotly_args)

    return fig
