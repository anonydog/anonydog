#!/usr/bin/env bash

if [ -z ${GITHUB_API_ACCESS_TOKEN+x} ]; then
  echo "need GITHUB_API_ACCESS_TOKEN"
  exit
fi

if [ -z ${REDIS_DATABASE_URL+x} ]; then
  echo "need REDIS_DATABASE_URL"
  exit
fi

WORK_DIR=$(cd "$(dirname "$0")"; pwd)
BUNDLE_GEMFILE=$WORK_DIR/Gemfile
BUNDLE_GEMFILE=$BUNDLE_GEMFILE bundle exec ruby -I $WORK_DIR/lib $WORK_DIR/lib/anonydog/poller.rb
