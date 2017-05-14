#!/usr/bin/env bash

RACKUP_CONFIG=webhook.config.ru

if [ -z ${GITHUB_API_ACCESS_TOKEN+x} ]; then
  echo "need GITHUB_API_ACCESS_TOKEN"
  exit
fi
if [ -z ${GITHUB_WEBHOOK_SECRET+x} ]; then
  echo "need GITHUB_WEBHOOK_SECRET"
  exit
fi
if [ -z ${GITHUB_SSH_KEY_PATH+x} ]; then
  echo "need GITHUB_SSH_KEY_PATH"
  exit
fi
if [ -z ${REDIS_DATABASE_URL+x} ]; then
  echo "need REDIS_DATABASE_URL"
  exit
fi

WORK_DIR=$(cd "$(dirname "$0")"; pwd)
BUNDLE_GEMFILE=$WORK_DIR/Gemfile
BUNDLE_GEMFILE=$BUNDLE_GEMFILE bundle exec rackup -s thin -o $IP -p $PORT $WORK_DIR/$RACKUP_CONFIG
