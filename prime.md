Hello, my dear reader

# TL;DR

We now can define an initial DB state in a generic and flexible way by writing tiny fragments of ruby

# Prime
Prime is a script filling the database with a minimal amount of data to be able to use most of the UI. Unlike seeds, prime generates randomized data and can be rune from time to time to bring the data up to date. Here is how you run it: 
 * `docker-compose run web rake dev:prime`
 * `docker-compose run web bash` and then `rake dev:prime`

Prime generation is described in `db/prime/prime_generator.rb` file. If you don't want to get technical, you probably only need the `PRIME_MODELS` constant defined right at the top pf the file. It is a dictionary enumerating all generated model types. Each model type requires 3 things to be defined:
 - `target_count`: After prime generation there will be at least this many of such objects
 - `current_count`: A lambda returning current count of such objects
 - `factory_options`: The options passed to FactoryBot to create new objects of required
To put it simple, we tell FactoryBot to create an N-sized list with the specified options, where N is either 0 (if there already are enough models), or `target_amount - current_count` if something needs to be done. 