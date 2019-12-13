# arcanebet/backend [![wercker status](https://app.wercker.com/status/bd58fc9e4800e174aa4a6a9216d83d0c/s/master "wercker status")](https://app.wercker.com/project/byKey/bd58fc9e4800e174aa4a6a9216d83d0c)

ArcaneBet betting backend

## Project documentation

Project docs can be found in the [docs directory](./docs).

## Project setup

### 1. With docker-compose

The project ships with `docker-compose.example.yml` file meant for local development. In order to use it you need to have Docker and Docker Compose installed on your machine.

1. Copy example docker-compose file and adjust it to your taste:

```sh
cp docker-compose.yml.example docker-compose.yml
```

2. Copy example .env file and adjust it to your taste:

```sh
cp .env.example .env
```

3. Replace the placeholders and blank variables in the `.env` file with values you got from the development team.

4. Connect to web container's bash and install the dependencies in the volume.

```sh
docker-compose run --rm web bash
bundle install
yarn install
exit
```

### 2. Directly on the host

1. Install all the necessary databases (postgres, mongodb, redis) with Homebrew:

```sh
brew install \
  postgresql \
  mongodb \
  redis
```

2. Install Ruby with tools of your choice (this guide will cover rbenv)

```sh
brew install rbenv
rbenv init
echo 'eval "$(rbenv init -)"' >> ~/.profile
source ~/.profile

rbenv install 2.5.1
rbenv local 2.5.1
echo "RBENV_VERSION=2.5.1" >> .env

gem install bundler
gem update --system
```

3. install Node.js and Yarn

```sh
brew install node@8
npm install -g yarn
```

4. Install project dependencies

```sh
bundle install
yarn install
```

## Database setup

Setting up development database comes in following steps:

1. Create database instance and initialize the schema"

```sh
rake db:create db:schema:load
```

2. Populate the database with seed and develoment (prime) data:

Initial data for all environments (currencies, backoffice users, etc)

```sh
rake db:seed
```

or alternatively (which does the same with one step):

```sh
rake db:setup
```

Development fixture data, such as dummy customers can be populated with prime command:

```sh
rake dev:prime
```

3. Load sports and market templates data required for odds feed processing:

```sh
rake radar:titles:load
rake odds_feed:markets:update
rake odds_feed:markets:categorize
```

## Running the project in develoment

### With docker-compose

After all dependencies and data is set up, you can run the entire stack With

```sh
docker-compose up
```

### Directly on the host

This project has a handful of services that can be tricky to run each in a separate terminal tab or window. Managing multiple processes is easier with tools like [foreman](https://github.com/ddollar/foreman).

To run the entire stack with foreman, first copy the Procfile example file:

```sh
cp Procfile.example Procfile
```

Then run the whole stack with foreman:

```sh
foreman start
```

## Debugging

If the application is running in Docker or with a process manager like foreman, it can be not so trivial to debug it.

With docker-compose accessing the debugger context is possible by attaching to the container where the code execution is stopped by the debugger. For example, if you called `byebug` or `binding.pry` in web container, to access the context you would need to attach to web container:

```sh
docker attach arcanebet_web_1
```

[Rails web console](https://github.com/rails/web-console) is a powerful tool that allows debugging context without stopping the code execution.

Debugging remote sessions managed by foreman is possible with [pry-remote](https://github.com/pry/pry/wiki/Remote-sessions).

## Sanity Checks

We use Werсker as the CI/CD system. It runs following sanity checks on the code during builds:

- rspec - Ruby automated tests
- rubocop - Ruby style guide checks
- brakeman - Ruby security checks
- eslint - Javascript style guide checks

## Deployment

Branch `master` is automatically deployed to staging environment on Heroku.
