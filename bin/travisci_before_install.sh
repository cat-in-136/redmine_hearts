#!/bin/bash
# inspired by https://gist.github.com/pinzolo/7599006

#REDMINE_VERSION="2.4.0"
PLUGIN_NAME=redmine_hearts

# Shelve the cache if exists
if [ -d redmine/vendor/bundle ]; then
  mv redmine/vendor /tmp/vendor
fi

# Shelve the plugin files to a temporary directory
cp -pr . /tmp/${PLUGIN_NAME}

# Get Redmine code
if [ -d redmine ]; then
  rm -rf redmine
fi
git clone -b ${REDMINE_VERSION} --depth=1 https://github.com/redmine/redmine.git

# Restore the cache if exists
if [ -d /tmp/vendor ]; then
  mv /tmp/vendor redmine/vendor
fi

# Copy the plugin files to plugin directory
cp -pr /tmp/${PLUGIN_NAME} redmine/plugins/${PLUGIN_NAME}

# Create necessary files
cat > redmine/config/database.yml <<_EOS_
test:
  adapter: sqlite3
  database: db/redmine_test.db
_EOS_
