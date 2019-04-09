require Rails.root.join('db/prime/prime_generator')

namespace :dev do
  desc 'Populates database with sample data for local development environment'
  task prime: :environment do
    PrimeGenerator.new.generate
  end

  namespace :odds_feed do
    desc 'Deletes all odds feed produced data'
    task clear: :environment do
      puts 'Destroying players ...'
      CompetitorPlayer.delete_all
      Player.delete_all
      puts 'Done!'

      puts 'Destroying competitors ...'
      EventCompetitor.delete_all
      Competitor.delete_all
      puts 'Done!'

      puts 'Destroying odds ...'
      Odd.delete_all
      puts 'Done!'

      puts 'Destroying markets ...'
      Market.delete_all
      puts 'Done!'

      puts 'Destroying events ...'
      Event.delete_all
      puts 'Done!'
    end
  end
end
