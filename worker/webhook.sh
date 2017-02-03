if [ -z ${GITHUB_API_ACCESS_TOKEN+x} ]; then
  echo "need GITHUB_API_ACCESS_TOKEN"
  exit
fi
bundle exec rackup -s thin -o $IP -p $PORT webhook.config.ru
