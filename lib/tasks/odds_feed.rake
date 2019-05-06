# frozen_string_literal: true

namespace :odds_feed do
  desc 'Prepares database for selected replay scenario'
  task prepare_replay: :environment do
    id = ENV.fetch('SCENARIO', OddsFeed::PrepareScenario::DEFAULT_SCENARIOS)

    ActiveRecord::Base.logger = nil
    OddsFeed::PrepareScenario.call(scenario_id: id)
  end

  desc 'Prepares database for staging feed'
  task prepare_staging: :environment do
    ActiveRecord::Base.logger = nil
    OddsFeed::Scenarios::PrepareDatabase.call
  end

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
    ScopedEvent.delete_all
    Event.delete_all
    EventScope.delete_all
    puts 'Done!'
  end

  desc 'Loads a single event by MATCH_ID environment variable'
  task load_event: :environment do
    match_id = ENV.fetch('MATCH_ID')
    EventsManager::EventLoader.call(match_id)
  end

  namespace :replay do
    task prepare_queue: :environment do
      raise 'You should provide scenario id' unless ENV['SCENARIO']

      OddsFeed::ReplayService.call(scenario_id: ENV['SCENARIO'])
    end
  end
end
