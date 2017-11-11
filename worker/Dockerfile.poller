FROM ruby:2.3.1
RUN apt-get update && apt-get install -y cmake
RUN mkdir /app
COPY . /app
WORKDIR /app
RUN bundle install
CMD bundle exec ruby -I lib lib/anonydog/poller.rb
