#!/usr/bin/env bash

# Usage example:
#     $ ANONYDOG_ENV=arraisbot ./deploy/scripts/poller.sh

MAIN_SCRIPT=poller.sh

if [ -z ${ANONYDOG_ENV+x} ]; then
  echo "need ANONYDOG_ENV"
  exit
fi
SCRIPTS_DIR=$(cd "$(dirname "$0")"; pwd)

ENVS_DIR=$(cd "$SCRIPTS_DIR/../envs"; pwd)
BIN_DIR=$(cd "$SCRIPTS_DIR/../../worker"; pwd)
MAIN=$BIN_DIR/$MAIN_SCRIPT

SELECTED_ENV_DIR="$ENVS_DIR/$ANONYDOG_ENV"

read -s -p "Please enter password for $ANONYDOG_ENV environment: " SELECTED_ENV_PASSWORD
echo

GITHUB_API_ACCESS_TOKEN=`openssl enc -aes-256-cbc -d -in $SELECTED_ENV_DIR/github_api_access_token.enc -k $SELECTED_ENV_PASSWORD`
REDIS_DATABASE_URL=`openssl enc -aes-256-cbc -d -in $SELECTED_ENV_DIR/redis_database_url.enc -k $SELECTED_ENV_PASSWORD`
MONGO_DATABASE_URL=`openssl enc -aes-256-cbc -d -in $SELECTED_ENV_DIR/mongo_database_url.enc -k $SELECTED_ENV_PASSWORD`

env GITHUB_API_ACCESS_TOKEN=$GITHUB_API_ACCESS_TOKEN \
    REDIS_DATABASE_URL=$REDIS_DATABASE_URL \
    MONGO_DATABASE_URL=$MONGO_DATABASE_URL \
    $MAIN