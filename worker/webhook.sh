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
bundle exec rackup -s thin -o $IP -p $PORT webhook.config.ru
