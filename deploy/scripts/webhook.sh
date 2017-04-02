#!/usr/bin/env bash

# Usage example:
#     $ ANONYDOG_ENV=arraisbot ./deploy/scripts/webhook.sh

MAIN_SCRIPT=webhook.sh

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

# TODO: This leaves the unencrypted ssh key on disk
# Decrypt file ssh_key.enc to ssh_key
openssl enc -aes-256-cbc -d -in $SELECTED_ENV_DIR/ssh_key.enc -out $SELECTED_ENV_DIR/ssh_key  -k $SELECTED_ENV_PASSWORD

GITHUB_API_ACCESS_TOKEN=`openssl enc -aes-256-cbc -d -in $SELECTED_ENV_DIR/github_api_access_token.enc -k $SELECTED_ENV_PASSWORD`
GITHUB_WEBHOOK_SECRET=`openssl enc -aes-256-cbc -d -in $SELECTED_ENV_DIR/github_webhook_secret.enc -k $SELECTED_ENV_PASSWORD`
GITHUB_SSH_KEY_PATH="$SELECTED_ENV_DIR/ssh_key"
GITHUB_SSH_KEY_PASSPHRASE='' # Using empty passphrase for now. Rugged does not seem to support password-protected keys

env GITHUB_API_ACCESS_TOKEN=$GITHUB_API_ACCESS_TOKEN \
    GITHUB_WEBHOOK_SECRET=$GITHUB_WEBHOOK_SECRET \
    GITHUB_SSH_KEY_PATH=$GITHUB_SSH_KEY_PATH \
    GITHUB_SSH_KEY_PASSPHRASE=$GITHUB_SSH_KEY_PASSPHRASE \
    RACK_ENV=production \
    IP=127.0.0.1 \
    PORT=5000 \
    $MAIN
