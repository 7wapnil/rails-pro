Hello, my dear reader

# TL;DR

We now can define an initial DB state in a generic and flexible way by writing timy fragments of ruby

# Prime
Prime is a script filling the database with a minimal amount of data to be able to use most of the UI. Unlike seeds, prime generates randomized data and can be rune from time to time to bring the data up to date. Here is how you run it: 
 * `docker-compose run web rake dev:prime`
 * `docker-compose run web bash` and then `rake dev:prime`

## How does it work exactly?
`lib/tasks/dev.rake` - this is the file with `dev:prime` rake task definition. It creates a dictionary of reasonable counts of different objects we want created. This config is passed into `PrimeGenerator` class which brings our database into the state we describe here. `db/prime/generator.rb` - is the file where PrimeGenerator is described. You don't have to read into every single line of code, what we really need are 2 last methods of this class - `current_counts` and `factory_list_options`. Before actually creating anything `#generate` checks how many object of each kind we already have and only creates as much as we need to reach the required count.

## OK, what's next?
Using some _ruby magic_ we can now adjust the database state we bring out system into by running a single command. You get bonus points if you've noticed that dictionary keys in `counts`, `current_counts` and `factory_list_options` dictionaries are the same.
* `counts` in `lib/tasks/dev.rake` - after `#generate` is done, the database contains at least ***THIS*** many of these objects.
* `current_counts` in `PrimeGenerator` - Using simple `ActiveRecord` calls we define how we count these objects.
* `factory_list_options` in `PrimeGenerator` - This one's a bit tricky. Our test infrastructure contains a wide variety of factories. `Factory.create :customer, :with_address` creates a perfectly randomized customer. `factory_list_options` contains the arguments for `FactoryBot#create_list`. It's safe to assume that writing `customer: [:customer, count, :with_address]` in `factory_list_options` is equivalent to `FactoryBot.create_list :customer, count, :with_address`. Or a more generic expression - `customer: [<arguments>] <=> FactoryBot.create_list(<arguments>)`
