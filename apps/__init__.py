from flask import Flask
import dash_bootstrap_components as dbc
import dash

server=Flask(__name__)

server.config['Debug'] = True

app = dash.Dash(__name__, server=server, external_stylesheets=[dbc.themes.BOOTSTRAP], url_base_pathname='/dash/')
app.config['suppress_callback_exceptions']=True