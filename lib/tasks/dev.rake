require Rails.root.join('db/prime/prime_generator')

namespace :dev do
  desc 'Populates database with sample data for local development environment'
  task prime: :environment do
    PrimeGenerator.new.generate
  end

  namespace :odds_feed do
    desc 'Deletes all odds feed produced data'
    task clear: :environment do
      puts 'Destroying odds ...'
      Odd.destroy_all
      puts 'Done!'

      puts 'Destroying markets ...'
      Market.destroy_all
      puts 'Done!'

      puts 'Destroying events ...'
      Event.destroy_all
      puts 'Done!'
    end
  end
end
