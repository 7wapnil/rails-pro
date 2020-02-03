# Why use Makefile? - https://makefile.site

branch := $(shell git rev-parse --abbrev-ref HEAD)

start:
	docker-compose up

start-light:
	docker-compose up -d redis mongo db web worker worker_odds_feed listener cable

start-prefeed:
	docker-compose up -d redis mongo db

stop:
	docker-compose down

logs-odds:
	docker-compose logs -t worker_odds_feed

logs-db:
	docker-compose logs -t db

bash:
	docker-compose run --rm web bash

attach:
	docker attach backend_web_1 # probably should get the full name first

db:
	rake db:migrate

db-reset:
	rake db:reset
	make db-init

# Make sure to set the following in .ENV file (if you're using docker)
# DATABASE_HOST=db
# DATABASE_USERNAME=postgres
# DATABASE_PASSWORD=
# REDIS_URL=redis://redis:6379/0
# MONGO_URL=mongodb://mongo:27017/arcanebet_development
# MONGO_TEST_URL=mongodb://mongo:27017/arcanebet_test
db-init:
	rake db:setup
	rake dev:prime

prepare-external-data:
	rake radar:titles:load
	rake odds_feed:markets:update
	rake odds_feed:markets:categorize

images:
	docker images

ps:
	docker-compose ps

db-dump-restore:
	apt-get install -y postgresql-client
	pg_restore --verbose --clean --no-acl --no-owner -h db -U postgres -d arcanebet_development tmp/arcanebet-latest.dump

c:
	rails console

# Not completely sure about it, but it kinda describes the flow I used to set up the dev environment
onboarding:
	cp docker-compose.yml.example docker-compose.yml
	cp .env.example .env
	# 0) Make sure to check valiadles in .env are correct (probably get relevant example from @badmanski)
	# 1) set RADAR_MQ_NODE_ID to random 4 digits & restart
	@make db-init
	@make start-prefeed
	@make prepare-external-data
	# 2) Make a call https://iodocs.betradar.com/ufstaging#Odds-Recovery-POST-Request-full-odds-recovery using RADAR_MQ_NODE_ID as Node ID

branch:
	git checkout $(ARGS) || git checkout -b $(ARGS)

new:
	git checkout master &&  git checkout -b $(ARGS)

master:
	git checkout master

.PHONY: app test spec lib docs bin config db tmp

# makes it possible to run "make aaa bbb" instead of "make aaa ARGS=bbb"
ARGS = $(filter-out $@,$(MAKECMDGOALS)) # https://stackoverflow.com/a/47008498
%:
  @:
