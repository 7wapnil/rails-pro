require 'faker'
require 'factory_bot_rails'

class PrimeGenerator
  PRIME_MODELS = {
    tournaments: {
      target_count: 6,
      current_count: lambda do
        EventScope.where(kind: EventScope::TOURNAMENT).count
      end,
      factory_options: %i[event_scope tournament]
    },
    categories: {
      target_count: 6,
      current_count: lambda do
        EventScope.where(kind: EventScope::CATEGORY).count
      end,
      factory_options: %i[event_scope category]
    },
    past_events: {
      target_count: 10,
      current_count: lambda { Event.past.count },
      factory_options: %i[event with_odds with_event_scopes]
    },
    live_events: {
      target_count: 5,
      current_count: lambda { Event.in_play.count },
      factory_options: %i[event with_odds with_event_scopes live]
    },
    upcoming_events: {
      target_count: 10,
      current_count: lambda { Event.upcoming.count },
      factory_options: %i[event with_odds with_event_scopes upcoming]
    },
    customers: {
      target_count: 20,
      current_count: lambda { Wallet.pluck(:customer_id).uniq.count },
      factory_options: %i[customer ready_to_bet with_address]
    },
    entries: {
      target_count: 15,
      current_count: lambda { Entry.count },
      factory_options: %i[entry with_random_wallet]
    },
    bets: {
      target_count: 10,
      current_count: lambda { Bet.count },
      factory_options: %i[bet accepted with_random_market]
    }
  }.freeze

  def initialize
    @counts = PRIME_MODELS.map { |k, v| [k, v[:target_count]] }.to_h
  end

  def generate
    count_correction!
    hardcoded_prerequisites
    populate_data
  end

  private

  def count_correction!
    @counts.keys.each do |k|
      @counts[k] = [@counts[k] - PRIME_MODELS[k][:current_count].call, 0].max
    end
  end

  def hardcoded_prerequisites
    titles
    producers
  end

  def titles
    puts 'Generating titles...'
    football_attrs = FactoryBot.attributes_for :title,
                                               name: 'Football',
                                               kind: Title::SPORTS
    Title.find_or_create_by football_attrs

    csgo_attrs = FactoryBot.attributes_for :title,
                                           name: 'CS:GO',
                                           kind: Title::ESPORTS
    Title.find_or_create_by csgo_attrs
  end

  def producers
    puts 'Generating producers...'
    FactoryBot.create :liveodds_producer, :healthy
    FactoryBot.create :prematch_producer, :healthy
  end

  def populate_data
    @counts.keys.each do |k|
      count = @counts[k]
      options = PRIME_MODELS[k][:factory_options]
      puts "Generating #{count} #{k}..."
      list_args = [options.first, count, options.drop(1)].flatten
      FactoryBot.create_list(*list_args)
    end
  end
end
