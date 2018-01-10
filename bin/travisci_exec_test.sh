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

## Execute UI test
#bundle exec rake -T | grep redmine:plugins:test:ui > /dev/null 2> /dev/null
#if [ "$?" -eq 0 ]; then
#  phantomjs --webdriver 0.0.0.0:4444 >> phantomjs.log &
#  bundle exec rake redmine:plugins:test:ui NAME=${PLUGIN_NAME}
#  retval=$?
#  killall phantomjs
#  cat phantomjs.log
#fi
if [ "$retval" -ne 0 ]; then
#  echo "Interrupt executing test."
  exit $retval
fi

exit $retval
