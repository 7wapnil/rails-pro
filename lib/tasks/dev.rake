require Rails.root.join('db/prime/prime_generator')

namespace :dev do
  desc 'Populates database with sample data for local development environment'
  task prime: :environment do
    PrimeGenerator.new.generate
  end
  task console: :environment do
    byebug
  end
end
