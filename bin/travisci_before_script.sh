#!/bin/bash
# inspired by https://gist.github.com/pinzolo/7599006

export REDMINE_LANG=en
export RAILS_ENV=test

#REDMINE_VERSION="2.4.0"
PLUGIN_NAME=redmine_hearts

cd redmine

bundle install --path=${BUNDLE_PATH:-vendor/bundle}

# Initialize redmine
bundle exec rake generate_secret_token
bundle exec rake db:migrate
bundle exec rake redmine:load_default_data

# Copy assets & execute plugin's migration
cp -r plugins/${PLUGIN_NAME}/test/fixtures/*.* test/fixtures
bundle exec rake redmine:plugins NAME=${PLUGIN_NAME}

# Start phantomjs
phantomjs --webdriver 0.0.0.0:4444 >> phantomjs.log &
