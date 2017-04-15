#!/usr/bin/env bash

# Usage example:
#     $ ANONYDOG_ENV=arraisbot ./deploy/scripts/webapp.sh

MAIN_SCRIPT=webapp.sh

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

MESSAGE_QUEUE_URL=`cat $SELECTED_ENV_DIR/message_queue_url`

env MESSAGE_QUEUE_URL=$MESSAGE_QUEUE_URL \
    RACK_ENV=production \
    IP=127.0.0.1 \
    PORT=4000 \
    $MAIN