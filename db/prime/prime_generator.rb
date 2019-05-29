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
      current_count: -> { Event.past.count },
      factory_options: %i[event with_odds with_event_scopes]
    },
    live_events: {
      target_count: 5,
      current_count: -> { Event.in_play.count },
      factory_options: %i[event with_odds with_event_scopes live]
    },
    upcoming_events: {
      target_count: 10,
      current_count: -> { Event.upcoming.count },
      factory_options: %i[event with_odds with_event_scopes upcoming]
    },
    customers: {
      target_count: 20,
      current_count: -> { Wallet.pluck(:customer_id).uniq.count },
      factory_options: %i[customer ready_to_bet with_address]
    },
    entries: {
      target_count: 15,
      current_count: -> { Entry.count },
      factory_options: %i[entry with_random_wallet]
    },
    bets: {
      target_count: 10,
      current_count: -> { Bet.count },
      factory_options: %i[bet accepted with_random_market]
    },
    withdrawals: {
      target_count: 10,
      current_count: lambda do
        interval = Time.zone.now.beginning_of_day..Time.zone.now.end_of_day
        Withdrawal.where(created_at: interval).count
      end,
      factory_options: %i[withdrawal]
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
    @football = find_title_or_create_by(name: 'Football', kind: Title::SPORTS)
    @cs_go = find_title_or_create_by(name: 'CS:GO', kind: Title::ESPORTS)
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

  def find_title_or_create_by(attributes)
    title = Title.find_by(attributes)
    return title if title

    FactoryBot.create(:title, attributes)
  end
end
