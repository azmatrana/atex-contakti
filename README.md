# Netdesk

NetDesk application

## SimpleForm usages

### Default checkbox

```ruby
form.input :boolean_variable, as: :custom_checkbox, wrapper: :checkbox, label: 'label_text'
```

## Development

### Getting started - Installing the application (development)

Build docker container

```shell
docker-compose build
```

Install Gems

```shell
docker-compose run app bundle install
```

Make the database structure up to date

```shell
docker-compose run app bundle exec rake db:migrate
```

Import the seeds

```shell
docker-compose run app bundle exec rake db:seed
```

[Install Redis](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-redis-on-ubuntu-16-04)

[Problem with charlock_holmes on Mac 10.13.3](https://github.com/brianmario/charlock_holmes/issues/117#issuecomment-347267575)

### Running the application

Create a ssh directory in your app directory

```shell
mkdir .ssl
```

Create a self signed certificate. It'll ask you for address data and you can specify what you like but for `Common Name` use: `localhost.ssl`

```shell
openssl req -new -newkey rsa:2048 -sha1 -days 365 -nodes -x509 -keyout .ssl/localhost.key -out .ssl/localhost.crt
```

Add localhost.ssl to /etc/hosts

```shell
echo "127.0.0.1 localhost.ssl" | sudo tee -a /etc/hosts
```

To start the regular webserver just use

```shell
./bin/rails_server
```

To start the SSL webserver open another terminal window and run

```shell
bundle exec thin start -p 3001 --ssl --ssl-key-file .ssl/localhost.key --ssl-cert-file .ssl/localhost.crt
```

Now the HTTP website is available via `localhost.ssl:3000` in your browser and the SSL website is running under `localhost.ssl:3001`.

To sign in to the super admin UI, go to https://localhost.ssl:3001/super_ui.

To start Danthes just use

```shell
./bin/danthes
```
To start Sidekiq just use

```shell
./bin/sidekiq
```

## Test coverage

To run full suite just use

```shell
bundle exec rake
```

To run only rspec just use

```shell
bundle exec rspec
```

To run only konacha just use

```shell
bundle exec rake konacha:run
```

To run konacha in serve mode just use

```shell
bundle exec rake konacha:serve
```

### Jenkins

To run project in Jenkins you can use next shell command

```shell
#!/bin/bash -e
export LC_ALL="en_US.UTF-8"
bundle install
cp config/database.yml.jenkins config/database.yml
cp config/danthes.example.yml config/danthes.yml
bundle exec rake db:drop db:create db:migrate RAILS_ENV=test
CI_BUILD=1 GENERATE_REPORTS=true SPEC_OPTS="--format html --out spec/reports/rspec.html" bundle exec rake ci:setup:rspec spec
CI_REPORTS=spec/reports KONACHA_REPORTS=true bundle exec rake konacha:run
```

## Deployment

To deploy on staging just use

```shell
cap staging deploy
```
To deploy on production just use

```shell
cap production deploy
```


To set environment variables use:

```shell
cap production config:set VARNAME=value
```

To remove them:

```shell
cap production config:remove key=VARNAME
```

`.env.staging` and `.env.production` files aren't automatically synchronized due to security and environment management, 
they're just templates/hints for variables of specific environment


# Receive EMails locally
  Install MailCatcher for local development
  See instructions from: https://mailcatcher.me/

WIT

1. Check that .env.staging file contains necessary Wit settings. Check .env.development, .env.production or .env.docker for reference
-- WIT_API_PROTOCOL should be https:// OR http://. Optional - If excluded API calls are made with http-protocol.
--- For example WIT_API_PROTOCOL=https://
-- WIT_API_HOST should be the url for API calls. Required.
--- For example WIT_API_HOST=example.com
-- WIT_API_PORT should be the port of API calls. Required.
--- For example WIT_API_PORT=8081
2. Settings for staging environment
WIT_API_HOST=korpimedia.net
WIT_API_PORT=3004

