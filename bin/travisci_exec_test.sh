#!/bin/bash
# inspired by https://gist.github.com/pinzolo/7599006

export REDMINE_LANG=en
export RAILS_ENV=test
retval=0

#REDMINE_VERSION="2.4.0"
PLUGIN_NAME=redmine_hearts

cd redmine

# Execute test
bundle exec rake redmine:plugins:test NAME=${PLUGIN_NAME}
retval=$?
if [ "$retval" -ne 0 ]; then
  echo "Interrupt executing test."
  exit $retval
fi

exit $retval
