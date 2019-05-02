# frozen_string_literal: true

namespace :odds_feed do
  desc 'Prepares database for selected replay scenario'
  task prepare_replay: :environment do
    id = ENV.fetch('SCENARIO', OddsFeed::PrepareScenario::DEFAULT_SCENARIOS)

    ActiveRecord::Base.logger = nil
    OddsFeed::PrepareScenario.call(scenario_id: id)
  end

  desc 'Deletes all odds feed produced data'
  task clear: :environment do
    ActiveRecord::Base.logger = nil
    OddsFeed::Clear.call
  end

  desc 'Prepares database for staging feed'
  task prepare_staging: :clear

  desc 'Loads a single event by MATCH_ID environment variable'
  task load_event: :environment do
    match_id = ENV.fetch('MATCH_ID')
    EventsManager::EventLoader.call(match_id)
  end
end
