# -*- coding: utf-8 -*-
import os
from datetime import date, datetime
import pandas as pd

import dash
from dash.dependencies import Input, Output
from dash import dcc
from dash import html
from flask_caching import Cache

import dash_bootstrap_components as dbc
from dash_bootstrap_templates import load_figure_template
from dash_holoniq_wordcloud import DashWordcloud

# custom pkgs
from apps.data import all_options, templates
from apps.graphs import tree_map, chart_type_plot, get_time_sentiments, get_wc_words
from apps.utils import get_df
from apps.layouts import dashboard_area
from apps import app

# load env variables
from dotenv import load_dotenv
load_dotenv()

server = app.server

# CACHE_CONFIG = dict(CACHE_TYPE = os.getenv('CACHE_TYPE'),
#     CACHE_REDIS_HOST = os.getenv('CACHE_REDIS_HOST'),
#     CACHE_REDIS_PORT = os.getenv('CACHE_REDIS_PORT'),
#     CACHE_REDIS_DB = os.getenv('CACHE_REDIS_DB'),
#     CACHE_REDIS_URL = os.getenv('CACHE_REDIS_URL'),
#     CACHE_DEFAULT_TIMEOUT = os.getenv('CACHE_DEFAULT_TIMEOUT'))

# cache = Cache()
# cache.init_app(app.server, config=CACHE_CONFIG)


load_figure_template(templates)

# layout
app.layout = html.Div([
    dashboard_area,
    dcc.Store(id='dataframe') #store queried data
])

# cascaded inputs
@app.callback(
    Output('policies-dropdown', 'options'),
    [Input('policy-category', 'value')])
def set_policy_options(selected_policy):
    if selected_policy == 'All':
        return [{'label': 'All', 'value':'all'}]
    else:
        return [{'label': i.capitalize(), 'value': i} for i in all_options[selected_policy]]

@app.callback(
    Output('policies-dropdown', 'value'),
    [Input('policies-dropdown', 'options')])
def set_policy_value(available_options):
   
    return available_options[0]['value']

# -------------------------------- query the data --------------------------------

# redis memory store which is available across processes
# and for all time.

def global_store(controls):
    
    df = get_df(controls)
    common_words = get_wc_words(df)
    
    print('time after getting df: %s' % (datetime.now()).strftime("%M:%S"))
    return df, common_words

@app.callback(
    Output('dataframe', 'data'),
    [
        Input('policy-category', 'value'),
        Input('policies-dropdown', 'value'),
        Input('sentiment', 'value'),
        Input('date-picker', 'date'),
        Input('tabs', 'active_tab'),
    ])   
def user_input(policy_category, selected_policy,sentiment,date_value, party):

    if date_value is not None:
        date_object = date.fromisoformat(date_value)
        
    controls = {
        'policy_category': policy_category,
        'selected_policy': selected_policy,
        'sentiment': sentiment,
        'date_value': date_object,
        'party': party
    }

    global_store(controls)
    print('time after getting controls: %s' % (datetime.now()).strftime("%M:%S"))
    return controls

# -------------------------------- update graph options(bar, hist and scatter) --------------------------------

@app.callback(
    Output('chart-figure', 'children'),
    [Input('chart-type', 'value'),
     Input('dataframe', 'data'),
     Input('dropdown', 'value')])
def update_figure(chart_type, controls, template):
    
    df, _ = global_store(controls)
    fig = dcc.Graph(figure = chart_type_plot(chart_type, df, template))
    print('time after updating chart: %s' % (datetime.now()).strftime("%M:%S"))
    return fig

# -------------------------------- load time series evolution of sentiments --------------------------------

@app.callback(
    Output('sentiment-evolution', 'children'),
    [Input('dataframe', 'data'),
    Input('dropdown', 'value')])
def update_time_sentiment(controls, template):
    
    df, _ = global_store(controls)
    time_sent = get_time_sentiments(df, template)
    
    fig = html.Div([
        html.P("Sentiment Evolution", className="bg-dark text-white p-2 mb-3"),
        dcc.Graph(figure=time_sent)
        ])
    print('time after updating sentiment graph: %s' % (datetime.now()).strftime("%M:%S"))
    
    return fig

# --------------------------------update word cloud --------------------------------

@app.callback(
    Output('word-cloud', 'children'),
    Input('dataframe', 'data'))
def update_word_cloud(controls):
    
    df, x = global_store(controls)
    
    std_comm_words = [(k,round((100-10)*((v - x[-1][1]) / (x[0][1] - x[-1][1])) + 10)) for k, v in x]
    
    wc = html.Div(
        [DashWordcloud(
            list = std_comm_words,
            height=300,
            width = 400,
            gridSize=16,
            color='#f0f0c0',
            backgroundColor='#001f00',
            shuffle=False,
            rotateRatio=0.5,
            shrinkToFit=True,
            shape='circle',
            hover=True
            )])
    
    fig = html.Div([
        html.P("Word Cloud", className="bg-dark text-white p-2 mb-3"),wc
        ], className='me-3')
    print('time after updating wc: %s' % (datetime.now()).strftime("%M:%S"))
    return fig

# -------------------------------- update tree map --------------------------------

@app.callback(
    Output('tree-map', 'children'),
    [Input('dataframe', 'data'),
    Input('dropdown', 'value')])
def update_tree_map(controls, template):
 
    df, comm = global_store(controls)
    tree_diagram = tree_map(comm, template)
    
    fig = html.Div([
        html.P("Tree Map", className="bg-dark text-white p-2 mb-3"),
        dcc.Graph(figure=tree_diagram)])
    print('time after updating tree map: %s' % (datetime.now()).strftime("%M:%S"))
    return fig

# -------------------------------- load sample tweets from the working dataframe --------------------------------

@app.callback(
    Output('tweet-table', 'children'),
    Input('dataframe', 'data'))
def update_table(controls):
    
    df, _ = global_store(controls)
    
    tweets = df.sample(n=100, random_state=101)   
    table_df = tweets[['party', 'tweet']]
    
    fig = html.Div(
        [html.P("Sample Tweets", className="bg-dark text-white p-2 mb-3"),
         html.Div(dbc.Table.from_dataframe(
             table_df, striped=True, bordered=True, hover=True, index=False),
                  style={"maxHeight": "300px", "overflow": "scroll", "font-size": "12px"})
         ])
    print('time after updating table: %s' % (datetime.now()).strftime("%M:%S"))
    
    return fig


if __name__ == '__main__':
    app.run_server(debug=True)