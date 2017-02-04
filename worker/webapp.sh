if [ -z ${GITHUB_API_ACCESS_TOKEN+x} ]; then
  echo "need GITHUB_API_ACCESS_TOKEN"
  exit
fi
if [ -z ${GITHUB_WEBHOOK_ENDPOINT+x} ]; then
  echo "need GITHUB_WEBHOOK_ENDPOINT"
  exit
fi
bundle exec rackup -s thin -o $IP -p $PORT webapp.config.ru
