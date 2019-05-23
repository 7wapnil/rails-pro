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

  desc 'Assign categories to market templates'
  task categorize_templates: :environment do
    puts 'Updating market templates...'

    MarketTemplate.select(:id, :name, :external_id, :category).each do |mt|
      mt.update_attributes(
        category: OddsFeed::Markets::CATEGORIES_MAP[mt.external_id]
      )
    end

    puts 'Done!'
  end

  namespace :markets do
    desc 'Update market templates'
    task update: 'radar:update_market_templates'

    desc 'Assign categories to market templates'
    task categorize: :categorize_templates
  end

  namespace :replay do
    desc 'Prepares database for selected replay scenario'
    task prepare: :prepare_replay

    desc 'Add scenario matches to the replay quueue'
    task prepare_queue: :environment do
      raise 'You should provide scenario id' unless ENV['SCENARIO']

      OddsFeed::ReplayService.call(scenario_id: ENV['SCENARIO'])
    end

    desc 'Prepares missing players for replay'
    task load_players: :environment do
      ActiveRecord::Base.logger = nil
      OddsFeed::ReplayPlayersLoader.call
    end
  end
end
