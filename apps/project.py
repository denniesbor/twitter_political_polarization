import pandas as pd
import re
import os
import datetime
import collections

from dash import Dash, dcc, html, callback, Input, Output, dash_table
import dash_bootstrap_components as dbc
from dash_bootstrap_components._components.Container import Container
from dash_bootstrap_templates import load_figure_template
from dash_holoniq_wordcloud import DashWordcloud

# custom pkgs
from apps import app
import plotly
import plotly.express as px
import plotly.graph_objs as go
import plotly.offline as pyo
from plotly.subplots import make_subplots

import pandas as pd
import numpy as np
from wordcloud import WordCloud, STOPWORDS, ImageColorGenerator

# Viz Pkgs
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib
matplotlib.use('Agg')

import nltk
nltk.download('punkt')
nltk.download('wordnet')
nltk.download('omw-1.4')
nltk.download('vader_lexicon')


"""plotly dashboards templates"""

templates = [
    "bootstrap",
    "crulean",
    "cosmo",
    "darkly",
    "flatly",
    "journal",
    "litera",
    "lumen",
    "lux",
    "materia",
    "minty",
    "morph",
    "pulse",
    "quartz",
    "sandstone",
    "simplex",
    "sketchy",
    "slate",
    "solar",
    "spacelab",
    "superhero",
    "vapor",
    "yeti",
    "zephyr",
]

# logo
PLOTLY_LOGO = "https://images.plot.ly/logo/new-branding/plotly-logomark.png"


CONTENT_STYLE = {
    "margin-left": "5rem",
    "margin-right": "5rem",
    "padding": "2rem 1rem",
}

# read test data

df_p = pd.read_csv('testcsv.csv')
df_p.dropna(inplace=True)

# remove empty tweets
df_p = df_p[df_p.clean_text != '']
df_p['Party'] = df_p['Party'].replace(['R','D',None], ['Republicans', 'Democrats','Other'], regex = True)
df_p.rename(columns = {'clean_text':'text'}, inplace = True)

# stopwords
stopwords_set = set(STOPWORDS)

# update stopwords set
stopwords_set.update(['s','will','amp','must','rt','american', 'americans','re','000'])

# navigation bar

output_container = html.Div()

# This loads all the figure template from dash-bootstrap-templates library,
# adds the templates to plotly.io and makes the first item the default figure template.
load_figure_template(templates)

# controls
controls = dbc.Card(
    [
        html.Div(
            [
                dbc.Label("Chart Type"),
                dcc.Dropdown(
                    id="chart-type",
                    options=['Histogram','Bar', 'Scatter'],
                    value="Bar",
                    clearable=False,
                    className="dropdown text-dark"
                ),
            ],
            className="mb-3"
        ),
        html.Div(
            [
                dbc.Label("Area"),
                dcc.Dropdown(
                    id="area",
                    options=['Social Policies','Geo Political Policies'],
                    value="Social Policies",
                    clearable=False,
                    className="dropdown text-dark"
                ),
            ],
            className="mb-3"
        ),
        html.Div(
            [
                dbc.Label("Sentiment"),
                dcc.Dropdown(
                    id="sentiment",
                    options=['All','Positive','Negative', 'Neutral'],
                    value="All",
                    clearable=False,
                    className="dropdown text-dark"
                ),
            ],
            className="mb-3"
        ),
            html.Div(
            [
                dbc.Label("Change Theme"),
                dcc.Dropdown(
                    id="dropdown",
                    options=templates,
                    value="spacelab",
                    clearable=False,
                    className="dropdown text-dark"
                ),
            ]
        )
    ],
    body=True,
)

tabs = dbc.Tabs(
    [
        dbc.Tab(label="Democrats and Republicans", tab_id="all"),
        dbc.Tab(label="Democrats", tab_id="Democrats"),
        dbc.Tab(label="Republicans", tab_id="Republicans"),
        
    ],
    id="tabs",
    active_tab="all",
    )


# the style arguments for the sidebar. We use position:fixed and a fixed width
SIDEBAR_STYLE = {
    "position": "relative",
    "top": 0,
    "left": 0,
    "bottom": 0,
    "width": "16rem",
    "padding": "2rem 1rem",
    "background-color": "#f8f9fa",
}

# the styles for the main content position it to the right of the sidebar and
# add some padding.
CONTENT_STYLE = {
    "margin-left": "2rem",
    "margin-right": "1rem",
    "padding": "2rem 1rem",
    "background-color": "#f8f9fa",
    "min-width": "150px"
}

sidebar = html.Div(
    [
        html.H2("Controls", className="text-dark"),
        html.Hr(),
        controls
    ],
    style=CONTENT_STYLE,
)

content = html.Div(dbc.Container(
    [  
        dbc.Row(
        [
            dbc.Col(tabs, md=12),
        ]),
        dcc.Loading(output_container),
    ],
    fluid=True,
))

app.layout = html.Div([
    dbc.Row(
                [
                    dbc.Col(sidebar, md=2),                    
                    dbc.Col(content, md=10),
                ],
                className="mt-4",
            ),
    ])


""" Charts """

# plotly object arguments
plotly_args = dict(legend=dict(
    yanchor="top",
    y=0.99,
    xanchor="left",
    x=0.8),
            margin={"r": 5, "t": 5, "l": 5, "b": 5})


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

    args = dict(
        color="Party",
        height=300,
        template = template,
        log_y = True
        )

    if chart_type == 'Histogram':
        fig = px.histogram(df,
                x="Compound Sentiment",
                histnorm = 'density',
                nbins = 20,
                text_auto = '.0f',
                **args)

    elif chart_type == "Bar":
        fig = px.histogram(df,
                x="Sentiment Value",
                barmode = 'group',
                text_auto = '.0f',
                **args)

    elif chart_type == "Scatter":
        df['Compound Sentiment'] = df['Compound Sentiment'].round(decimals=3)
        df = df[['Compound Sentiment','Party','tweet_id']].groupby(['Compound Sentiment','Party']).count()
        df = df.reset_index()
        fig = px.scatter(df, x='Compound Sentiment',
                            y='tweet_id',
                            labels={
                            "Compound Sentiment": "Sentiment Label (-1 - 1)",
                            "tweet_id": "Value Count"
                            },
                            **args)

    fig.update_layout(**plotly_args)

    return fig

# plot tweet sentiment timeseries
def get_time_sentiments(df, template):

  '''This function calculates the volume of neutral, negative, 
  and positive tweets since the start of the year 2022
  
  parameters
  -------------
  input: pandas.DataFrame
    pandas dataframe object

  return: object
    plotly object
  
  '''
  
  df["created_at"] = pd.to_datetime(df.created_at)
  df = df[df["created_at"] >= '2022-01-01']
  df = df.resample('D', on='created_at')["Sentiment Value"].value_counts().unstack(1)
  df.reset_index(inplace=True)
  df = df.melt("created_at", var_name='sentiment',  value_name='vals')
  fig = px.line(df, x="created_at", y="vals", color='sentiment',height=300,
                labels={
                    'created_at':'Date',
                    'vals':'Count'
                },
                template=template)
  fig.update_layout(**plotly_args)

  return fig

# plot word cloud
def plot_wc(df, mask=None, max_words=200, max_font_size=100, figure_size=(8,12), color = 'white',
                   title = None, title_size=40, image_color=False):
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

  fig = plt.figure(figsize=figure_size,dpi=300)
  text = " ".join(tweet for tweet in df["text"])
  wordcloud = WordCloud(background_color=color,
                  stopwords = stopwords_set,
                  random_state = 42,
                  width=400, 
                  height=500,
                  mask = mask)
  wordcloud.generate(str(text))
  if image_color:
    image_colors = ImageColorGenerator(mask);
    plt.imshow(wordcloud.recolor(color_func=image_colors), interpolation="bilinear");
    plt.title(title, fontdict={'size': title_size,  
                              'verticalalignment': 'bottom'})
  else:
    plt.imshow(wordcloud,interpolation="bilinear");
  plt.axis("off")
  
  return fig

def clean_tweets(tweet:str):
    
  """ This function cleans the tweets

  Attrs
  ---------
  input: str
    tweet
  Returns
  ---------
  output: str
    clean tweet 
  """
  
  tweet = tweet.lower()

  #Remove twitter handlers
  tweet = re.sub('@[^\s]+','',tweet)

  #remove hashtags
  tweet = re.sub(r'\B#\S+','',tweet)

  # Remove URLS
  tweet = re.sub(r"http\S+", "", tweet)

  # Substituting multiple spaces with single space
  tweet = re.sub(r'\s+', ' ', tweet, flags=re.I)

  # Remove all the special characters
  tweet = ' '.join(re.findall(r'\w+', tweet))

  #remove all single characters
  tweet = re.sub(r'(^| ).(( ).)*( |$)', '', tweet)

  return tweet

# wc list
def get_wc_list(df,max_word_count=100):
    

    text = ""

    temp_dataset = df['text']

    for review in temp_dataset:
        review = clean_tweets(review)
        text += review
        text += "\n"

    tokenizer = nltk.RegexpTokenizer(r"\w+")
    tokenized_review = tokenizer.tokenize(text.lower())
    filtered_review = [word for word in tokenized_review if word not in stopwords_set]

    frequency = dict(collections.Counter(filtered_review))
    vals = sorted(frequency.values(), reverse=True)[:max_word_count]
    
    min_val = min(vals)
    max_val = max(vals)
    
    wc_values = [[k,round((100-10)*((v - min_val) / (max_val - min_val)) + 10)] for k, v in sorted(frequency.items(), key=lambda x: x[1], reverse=True)]

    return wc_values[:max_word_count]

# tree map
def tree_map(df, template):
    ''' function which takes a dataframe of tweets and returns tree map
        as a Plotly object

    params:
    -----------
    input: pandas dataframe
        df

    returns
    ----------
    output: obj
        plotly figure
    '''

    all_words = [item for sublist in [(clean_tweets(word)).split(' ') for word in list(df.text)] for item in sublist if item not in stopwords_set]
    all_words=pd.Series(np.array(all_words))
    common_words=all_words.value_counts()[:70].rename_axis('Common Words').reset_index(name='count')
    fig = px.treemap(common_words, path=['Common Words'], values='count',width=800, height=300, template=template)

    fig.update_layout(**plotly_args)
    
    return fig


@app.callback(
    Output(output_container, "children"),
    [Input('dropdown', "value"),
        Input("chart-type", "value"),
        Input("area", "value"),
        Input("sentiment", "value"),
        Input("tabs","active_tab")
    ]
    )
def update(template,chart_type,area,sentiment,tabs):
 
    # dff = df[df.year.between(1952, 1982)]
    # dff = dff[dff.continent.isin(df.continent.unique()[1:])]
    
    
    if tabs != 'all':
        
        df = df_p[df_p.Party==tabs]
    else:
        df = df_p.copy()
        
    if sentiment == 'All':
        df = df[(df.category==area)]
    
    else:
        df = df[(df.category==area) & (df['Sentiment Value']==sentiment.lower())]
      
    chart = chart_type_plot(chart_type, df, template)
    time_sent = get_time_sentiments(df, template)
    # wc = plot_wc(df)
    tree_diagram = tree_map(df, template)

    tweets = df.sample(n=100, random_state=101)
    
    table_df = tweets[['Party', 'tweet']]
    
    
    table = html.Div(
       [html.P("Sample Tweets", className="bg-dark text-white p-2 mb-3"),
        html.Div(dbc.Table.from_dataframe(
        table_df, striped=True, bordered=True, hover=True, index=False
 
    ),
                 style={"maxHeight": "300px", "overflow": "scroll"})],
        className="mt-3",
        )

    # wordcloud
    
    wc = html.Div([
        DashWordcloud(
            id='wordcloud',
            list=get_wc_list(df),
            width=450, height=300,
            gridSize=16,
            color='#f0f0c0',
            backgroundColor='#001f00',
            shuffle=False,
            rotateRatio=0.5,
            shrinkToFit=True,
            shape='circle',
            hover=True
            )
        ])

    if dcc.Graph(figure=chart):
        
        print('hey')
        
    print('Hello world')
    return html.Div(
        [
        
            dbc.Row(
                [
                    dbc.Col(
                        html.Div([
                            html.P("Sentiment Distribution", className="bg-dark text-white p-2 mb-3"),dcc.Graph(figure=chart)
                            ]), lg=5),
                    
                    dbc.Col(html.Div([
                        html.P("Sentiment Evolution", className="bg-dark text-white p-2 mb-3"),dcc.Graph(figure=time_sent)
                        ]), lg=5),
                ],
                className="mt-4",
            ),
            dbc.Row(
                [
                    
                    dbc.Col(html.Div([
                        html.P("Word Cloud", className="bg-dark text-white p-2 mb-3"),wc
                        ], className='me-3'), lg=4),
                    
                    dbc.Col(html.Div([
                        html.P("Tree Map", className="bg-dark text-white p-2 mb-3"),dcc.Graph(figure=tree_diagram)
                                      ]), lg=8),
                ],
                className="mt-4",
            ),
            dbc.Row(
                [
                    dbc.Col(
                        table, lg=8
                    )
                ]
            )
        ],
    )

if __name__ == "__main__":
    app(debug=True)