from flask.cli import FlaskGroup
from apps.routes import app
# 
server = app.server

cli = FlaskGroup(app)

if __name__ == "__main__":
    cli()
