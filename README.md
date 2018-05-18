# arcanebet

[ ![Codeship Status for arcanebet/arcanebet](https://app.codeship.com/projects/bec721c0-29eb-0136-53e1-72ca75b7ec4b/status?branch=master)](https://app.codeship.com/projects/287403)

ArcaneBet betting backend

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

To launch the application stack run:

```
$ docker-compose up -d
```

To attach to container and interact with byebug debugger console (given that your web container name is `arcanebet_web_1`) run:

```
$ docker exec arcanebet_web_1
```

## Sanity Checks

We use Codeship as the CI/CD system. It runs following sanity checks on the code during builds:

- rspec - Ruby automated tests
- rubocop - Ruby style guide checks
- brakeman - Ruby security checks
- eslint - Javascript style guide checks

## Deployment

Branch `master` is automatically deployed to staging environment on Heroku.
