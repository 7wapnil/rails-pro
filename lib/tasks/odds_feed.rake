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
end
