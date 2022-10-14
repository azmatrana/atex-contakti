FROM ruby:2.2.4
MAINTAINER alex@amoniac.eu

ENV PG_MAJOR 9.5
ENV APP_HOME /app
ENV RACK_ENV=development
ENV PHANTOM_JS_VERSION="1.9.8"
ENV PHANTOM_JS="phantomjs-1.9.8-linux-x86_64"

EXPOSE 3000

RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update && apt-get install -y libpq-dev postgresql-client-$PG_MAJOR libxml2-dev libxslt1-dev unzip imagemagick libicu-dev \
    && curl -L -O https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2 \
    && tar xvjf $PHANTOM_JS.tar.bz2 \
    && mv $PHANTOM_JS /usr/local/share \
    && ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin \
    && mkdir -p /root/.phantomjs/$PHANTOM_JS_VERSION/x86_64-linux/bin \
    && ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /root/.phantomjs/$PHANTOM_JS_VERSION/x86_64-linux/bin/phantomjs \
    && apt-get clean \
    && gem install bundler -v 1.15.4 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
ENV RAILS_ENV=development
CMD ./bin/rails_server
