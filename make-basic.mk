bundle:
	bundle install

c:
	rails console

style:
	rubocop --fail-fast

summer:
	bin/spring stop

# DEV ENV SETUP INSTRUCTIONS

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

prepare-external-data:
	rake radar:titles:load
	rake odds_feed:markets:update
	rake odds_feed:markets:categorize
