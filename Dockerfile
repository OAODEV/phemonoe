FROM alpine:edge
MAINTAINER tym@adops.com

# Install python and pipenv
RUN apk add --no-cache python py-pip git py-psycopg2
RUN set -ex && pip install pipenv --upgrade
COPY Pipfile app/
WORKDIR /app

# Pipenv warns of 'unexpected behavior' if these aren't set
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install requirements into the container
# NOTE: there is a bit of cargo-cult voodoo here:
# `pipenv install` should create a lock file if it doesn't find one.
# That currently breaks the build if we don't explicitly lock beforehand.
# Not clear what the difference is, but it works for now.
RUN pipenv lock
RUN pipenv install --system


# SQueaLy repo does not include `setup.py` but cloning suffices here:
RUN git clone https://github.com/hashedin/squealy.git
WORKDIR /app/squealy

# Add settings for production:
COPY production.py /app/squealy/squealyproj/
ENV DJANGO_SETTINGS_MODULE=squealyproj.production

# pyathenajdbc won't work without Java in the container,
# and we won't be using it anyway.
# This comments out the only place it gets imported:
RUN sed -e '/pyathenajdbc/ s/^#*/# /' -i /app/squealy/squealy/views.py

# TODO: remove whitenoise requirement, and serve static assets from GCS.
RUN python manage.py collectstatic

CMD python manage.py migrate \
&& gunicorn -b 0.0.0.0:8000 squealyproj.wsgi
