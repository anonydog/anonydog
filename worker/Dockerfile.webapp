FROM ruby:2.2

RUN apt-get update -qq && apt-get install -y build-essential cmake

ENV APP_HOME /app  
RUN mkdir $APP_HOME  
WORKDIR $APP_HOME

ADD Gemfile* $APP_HOME/  
RUN bundle install

ADD . $APP_HOME  

CMD bundle exec rackup -s thin -o 0.0.0.0 -p 80 webapp.config.ru
