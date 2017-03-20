#!/usr/bin/env bash

RACKUP_CONFIG=webapp.config.ru

if [ -z ${GITHUB_API_ACCESS_TOKEN+x} ]; then
  echo "need GITHUB_API_ACCESS_TOKEN"
  exit
fi
if [ -z ${GITHUB_WEBHOOK_ENDPOINT+x} ]; then
  echo "need GITHUB_WEBHOOK_ENDPOINT"
  exit
fi
if [ -z ${GITHUB_WEBHOOK_SECRET+x} ]; then
  echo "need GITHUB_WEBHOOK_SECRET"
  exit
fi

WORK_DIR=$(cd "$(dirname "$0")"; pwd)
BUNDLE_GEMFILE=$WORK_DIR/Gemfile
BUNDLE_GEMFILE=$BUNDLE_GEMFILE bundle exec rackup -s thin -o $IP -p $PORT $WORK_DIR/$RACKUP_CONFIG
