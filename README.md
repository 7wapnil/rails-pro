# arcanebet

[![wercker status](https://app.wercker.com/status/bd58fc9e4800e174aa4a6a9216d83d0c/s/master "wercker status")](https://app.wercker.com/project/byKey/bd58fc9e4800e174aa4a6a9216d83d0c)

ArcaneBet betting backend

## Project documentation

- Odds feed
    - [WebSocket signals documentation](docs/odds-feed/websocket-emits.md)


## Development

The project ships with `docker-compose.example.yml` file meant for local development. In order to use it you need to have Docker and Docker Compose installed on your machine.

1. Copy example docker-compose file and adjust it to your taste:

```
$ cp docker-compose.yml.example docker-compose.yml
```

2. Copy example .env file and adjust it to your taste:

```
$ cp .env.example .env
```

Put the values you got from the development team into .env

Connect to web container's bash and install the dependencies in the volume
```
docker-compose run --rm web bash
bundle install
exit
```

To launch the application stack run:

```
$ docker-compose up -d
```

To attach to container and interact with byebug/pry debugger console (given that your web container name is `arcanebet_web_1`) run:

```
$ docker attach arcanebet_web_1
```

To detach without terminating process use shortcut: `Ctrl + P + Q`.

### Database setup

Setting up development database comes in following steps:

1. Create database instance and initialize the schema"

```
$ rake db:create db:schema:load
```

or alternatively (which does the same with one step):

```
$ rake db:setup
```

2. Populate the database with seed and develoment (prime) data:

Initial data for all environments (i.e. backoffice users) (is automatically executed by `rake db:setup`)

```
$ rake db:seed
```

Development fixture data that simulates production (i.e. events and markets, customers, etc.)

```
$ rake dev:prime
```

## Back-office frontend setup
Launch web container's bash and execute the following:

```bash
npm install
./bin/webpack-dev-server
```

This process has to keep running while you work with the admin panel


## Sanity Checks

We use Werсker as the CI/CD system. It runs following sanity checks on the code during builds:

- rspec - Ruby automated tests
- rubocop - Ruby style guide checks
- brakeman - Ruby security checks
- eslint - Javascript style guide checks

## Deployment

Branch `master` is automatically deployed to staging environment on Heroku.
