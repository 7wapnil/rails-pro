require Rails.root.join('db/prime/generator')

namespace :dev do
  desc 'Populates database with sample data for local development environment'
  task prime: :environment do
    counts = {
      tournaments: 6,
      categories: 6,
      past_events: 10,
      live_events: 5,
      upcoming_events: 10,
      bets: 15,
      customers: 30
    }
    PrimeGenerator.new(counts: counts).generate
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
