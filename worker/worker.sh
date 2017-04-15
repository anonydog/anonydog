#!/usr/bin/env bash

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
if [ -z ${MESSAGE_QUEUE_URL+x} ]; then
  echo "need MESSAGE_QUEUE_URL"
  exit
fi

WORK_DIR=$(cd "$(dirname "$0")"; pwd)
BUNDLE_GEMFILE=$WORK_DIR/Gemfile
BUNDLE_GEMFILE=$BUNDLE_GEMFILE bundle exec ruby -I $WORK_DIR/lib $WORK_DIR/lib/anonydog/worker.rb
