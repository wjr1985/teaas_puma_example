FROM ruby:2.3.1-alpine

RUN apk add --update \
      imagemagick-dev \
      git \
      build-base

ENV APP_HOME /app

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile $APP_HOME
RUN bundle install

COPY . $APP_HOME
EXPOSE 4567
CMD ["bundle","exec","ruby","main.rb"]
