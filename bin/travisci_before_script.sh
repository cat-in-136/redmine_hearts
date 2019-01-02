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

# Execute plugin's migration
bundle exec rake redmine:plugins NAME=${PLUGIN_NAME}
