#!/bin/bash
# inspired by https://gist.github.com/pinzolo/7599006

export REDMINE_LANG=en
export RAILS_ENV=test

#REDMINE_VERSION="2.4.0"
PLUGIN_NAME=redmine_hearts

# https://www.redmine.org/issues/30353
if [ "v${REDMINE_VERSION:0:2}" = "v3." ]; then
  rvm @global do gem uninstall bundler -x -v ">= 2.0" 
  gem install bundler -v "< 2.0" 
fi

cd redmine

bundle install --path=${BUNDLE_PATH:-vendor/bundle}

# Initialize redmine
bundle exec rake generate_secret_token
bundle exec rake db:migrate
bundle exec rake redmine:load_default_data

# Execute plugin's migration
bundle exec rake redmine:plugins NAME=${PLUGIN_NAME}
