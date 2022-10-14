#!/bin/bash -e
export LC_ALL="en_US.UTF-8"
bundle install
cp config/database.yml.jenkins config/database.yml
cp config/danthes.example.yml config/danthes.yml
bundle exec rake db:drop db:create db:migrate RAILS_ENV=test
CI_BUILD=1 GENERATE_REPORTS=true SPEC_OPTS="--format html --out spec/reports/rspec.html" bundle exec rake ci:setup:rspec spec
CI_REPORTS=spec/reports KONACHA_REPORTS=true bundle exec rake konacha:run
