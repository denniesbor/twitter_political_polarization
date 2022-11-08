# pull official base image
FROM python:3.10.6-slim-buster

ENV WORKDIR=/usr/app

# set work directory
WORKDIR $WORKDIR

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt $WORKDIR/requirements.txt
RUN pip install -r requirements.txt

RUN export FLASK_APP=apps/__init__.py
# copy project
COPY . $WORKDIR

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "manage:server"]