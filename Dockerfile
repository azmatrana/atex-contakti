FROM phusion/passenger-ruby22:0.9.28

ENV HOME /root
ENV PG_MAJOR 9.5
ENV APP_HOME /home/app/webapp
ENV RACK_ENV=production
ENV RAILS_ENV=production
ENV RAILS_USE_SSL=true
EXPOSE 3000 9292
VOLUME ["/home/app/webapp/public/uploads"]
VOLUME ["/home/app/webapp/public/chatuploads"]

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 \
    && echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update && apt-get install -y libpq-dev postgresql-client-$PG_MAJOR libxml2-dev libxslt1-dev unzip imagemagick \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p $APP_HOME && mkdir -p /etc/my_init.d/
#&& gem install bundler rake --no-ri --no-rdoc

# Add workers
ADD ./bin/workers /etc/service/sidekiq/run
ADD ./bin/faye /etc/service/faye/run
# Enable passenger
RUN rm /etc/nginx/sites-enabled/default
ADD docker/nginx.conf /etc/nginx/sites-enabled/default
ADD docker/deploy_tasks.sh /etc/my_init.d/deploy_tasks.sh
COPY Gemfile /tmp/bundle-cache/Gemfile
COPY Gemfile.lock /tmp/bundle-cache/Gemfile.lock
RUN chown -R app /tmp/bundle-cache
RUN su app -c 'cd /tmp/bundle-cache && \
                       bundle install \
                            --jobs=4 \
                            --path=/home/app/bundle \
                            --no-cache \
                            --deployment --without test development doc'
RUN cp -a /tmp/bundle-cache/.bundle $APP_HOME
WORKDIR $APP_HOME
COPY / $APP_HOME
ADD docker/dokku.nginx.sigil $APP_HOME/nginx.conf.sigil
ADD docker/default_env.conf /etc/nginx/main.d/default_env.conf
RUN chown -R app:app $APP_HOME
RUN su app -c 'cd /home/app/webapp && bundle exec rake assets:precompile'
RUN rm -f /etc/service/nginx/down
CMD ["/sbin/my_init"]
