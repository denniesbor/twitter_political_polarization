from flask import render_template, request, url_for
from apps.project import app


@app.server.route('/')
def dashboard():
    return render_template('index.html', variable_in_template=app.index())

@app.server.route('/about/')
def about():
    return render_template('about.html')