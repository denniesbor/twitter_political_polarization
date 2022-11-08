# pull official base image
FROM python:3.10.6-slim-buster as base

ENV WORKDIR=/usr/app

# set work directory
WORKDIR $WORKDIR

# install dependencies
RUN python -m venv .venv && \
    .venv/bin/pip install --no-cache-dir -U pip setuptools

COPY ./requirements.txt $WORKDIR/requirements.txt

RUN .venv/bin/pip install --no-cache-dir -r requirements.txt && \
    find $WORKDIR/.venv \( -type d -a -name test -o -name tests \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \+


# Now multistage build
FROM python:3.10.6-slim-buster

# set work directory
WORKDIR /usr/app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY --from=base /usr/app /usr/app

# copy project
COPY . $WORKDIR

ENV PATH="/usr/app/.venv/bin:$PATH"

RUN export FLASK_APP=apps/__init__.py

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "manage:server"]