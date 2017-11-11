FROM ruby:2.3.1
RUN apt-get update && apt-get install -y cmake
RUN apt-get install -y libssl-dev libssh2-1 libssh2-1-dev
RUN mkdir /app
COPY . /app

WORKDIR /app

RUN bundle install

VOLUME /data/ssh

ENV GITHUB_SSH_KEY_PATH /data/ssh/ssh_key

CMD bundle exec rackup -s thin -o 0.0.0.0 -p 80 webhook.config.ru
