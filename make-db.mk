db:
	rake db:migrate

db-reset:
	rake db:reset
	make db-init

db-dump-restore:
	pg_restore --verbose --clean --no-acl --no-owner -h db -U postgres -d arcanebet_development tmp/arcanebet-latest.dump

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
