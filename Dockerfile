FROM ruby:2.5.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /arcanebet
WORKDIR /arcanebet
COPY Gemfile /arcanebet/Gemfile
COPY Gemfile.lock /arcanebet/Gemfile.lock
RUN bundle install
COPY . /arcanebet   
