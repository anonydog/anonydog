#!/usr/bin/env bash

RACKUP_CONFIG=webapp.config.ru

if [ -z ${MESSAGE_QUEUE_URL+x} ]; then
  echo "need MESSAGE_QUEUE_URL"
  exit
fi

WORK_DIR=$(cd "$(dirname "$0")"; pwd)
BUNDLE_GEMFILE=$WORK_DIR/Gemfile
BUNDLE_GEMFILE=$BUNDLE_GEMFILE bundle exec rackup -s thin -o $IP -p $PORT $WORK_DIR/$RACKUP_CONFIG
