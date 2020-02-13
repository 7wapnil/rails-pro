# Set of commands for development with docker

start:
	docker-compose up

start-lite:
	docker-compose up -d redis mongo db web worker worker_odds_feed listener cable

start-prefeed:
	docker-compose up -d redis mongo db

stop:
	docker-compose down

logs-odds:
	docker-compose logs -t worker_odds_feed

logs-db:
	docker-compose logs -t db

run:
	docker-compose run --rm web $(ARGS)

bash:
	docker-compose run --rm web bash

attach:
	docker attach backend_web_1 # probably should get the full name first

images:
	docker images

ps:
	docker-compose ps

watch:
	docker-compose run --rm web bundle exec guard
