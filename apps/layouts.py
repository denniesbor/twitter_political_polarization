from datetime import date, datetime, timedelta
import boto3
import base64
from botocore.exceptions import ClientError

from dash import dcc
from dash import html

import dash_bootstrap_components as dbc
from apps.data import templates, all_options


# -------------------------------- Side bar --------------------------------

custom_style = {
    "fontWeight": "700",
    "color": "#000000",
    "fontSize": "14px",
    "margin-bottom": "4px",
}

# cascaded menu
cascaded_policy_menu = html.Div(
    [
        dbc.Label("Policy Category", style=custom_style),
        dcc.Dropdown(
            id="policy-category",
            options=[{"label": k, "value": k} for k in all_options.keys()],
            value="Social Policies",
            clearable=False,
            className="dropdown text-dark mb-6",
        ),
        html.Div(
            [
                dbc.Label("Policy", className="text-dark", style=custom_style),
                dcc.Dropdown(id="policies-dropdown", className="mb-6", clearable=False),
            ]
        ),
    ],
    className="mb-6",
)

# sentiment choice
sentiment_choice = html.Div(
    [
        dbc.Label("Sentiment", className="text-dark", style=custom_style),
        dcc.Dropdown(
            id="sentiment",
            options=["All", "Positive", "Negative", "Neutral"],
            value="All",
            clearable=False,
            className="dropdown text-dark",
        ),
    ],
    className="mb-6",
)

# graph themes
template_choice = html.Div(
    [
        dbc.Label("Change Graph Theme", className="text-dark", style=custom_style),
        dcc.Dropdown(
            id="dropdown",
            options=templates,
            value="spacelab",
            clearable=False,
            className="dropdown text-dark",
        ),
    ]
)

# date picker
date_picker = html.Div(
    [
        dbc.Label("Pick Start Date", className="text-dark", style=custom_style),
        html.Div(
            [
                dcc.DatePickerSingle(
                    id="date-picker",
                    min_date_allowed=date(2021, 1, 1),
                    max_date_allowed=(datetime.now() - timedelta(days=31)).date(),
                    initial_visible_month=(datetime.now() - timedelta(days=180)).date(),
                    date=(datetime.now() - timedelta(days=180)).date(),
                )
            ]
        ),
        dbc.Label(
            "For the best user experience, data within a six-month window from the selection date is displayed",
            color="secondary",
        ),
    ]
)

sidebar = html.Div(
    [
        html.Div(
            [html.P("This webpage is not designed for small-screen devices!!")],
            className="alert alert-danger",
        ),
        html.H2("Controls", className="text-dark text-center mb-6"),
        dbc.Card(
            [date_picker, cascaded_policy_menu, sentiment_choice, template_choice],
            body=True,
        ),
    ],
    style={
        "margin-right": 0,
        "margin-bottom": "1rem",
        "padding": 0,
        "background-color": "#f8f9fa",
    },
)

# -------------------------------- Main Section Layout--------------------------------

# chart type selections
items = [
    "Bar",
    "Histogram",
    "Scatter",
]

hist_bar_scatter = html.Div(
    [
        dbc.Row(
            [
                dbc.Col(
                    html.P(
                        "Sentiment Distribution",
                        className="bg-dark text-white p-2 mb-3",
                    ),
                    lg=7,
                ),
                dbc.Col(
                    dcc.Dropdown(
                        options=items,
                        value="Bar",
                        id="chart-type",
                        clearable=False,
                        className="dropdown text-dark m-1",
                        style={"width": "100%"},
                    ),
                    lg=5,
                ),
            ]
        ),
        html.Div(id="chart-figure", className="mt-6"),
    ]
)

# output container
output_container = html.Div(
    [
        dbc.Row(
            [
                dbc.Col(hist_bar_scatter, lg=6),
                dbc.Col(html.Div(id="sentiment-evolution"), lg=6),
            ],
            style={"margin-top": 0, "padding": 0, "border": 0},
        ),
        dbc.Row(
            [
                dbc.Col(html.Div(id="word-cloud"), lg=4),
                dbc.Col(html.Div(id="tree-map"), lg=5, className="mb-3"),
                dbc.Col(html.Div(id="tweet-table"), lg=3, className="mb-3"),
            ],
            style={"margin-top": 0, "padding": 0, "border": 0, "margin-bottom": "2rem"},
        ),
    ]
)

# navigation tabs
tabs = dbc.Tabs(
    [
        dbc.Tab(label="Democrats and Republicans", tab_id="all", className="p-4"),
        dbc.Tab(label="Democrats", tab_id="Democrats", className="p-4"),
        dbc.Tab(label="Republicans", tab_id="Republicans", className="p-4"),
    ],
    id="tabs",
    active_tab="all",
    style={"fontsize": "12px"},
)

# page container
content = html.Div([html.Div(tabs, className="mb-4"), dcc.Loading(output_container)])

# --------- Dashboards --------------------------------

dashboard_area = dbc.Row(
    [dbc.Col(sidebar, md=2), dbc.Col(content, md=10)], className="mt-4"
)
