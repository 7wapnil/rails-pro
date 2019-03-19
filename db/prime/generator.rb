class PrimeGenerator
  def initialize(counts:)
    @counts = counts
  end

  def generate
    count_correction!
    hardcoded_prerequisites
    populate_data
  end

  private

  def count_correction!
    @counts.keys.each do |k|
      @counts[k] = [@counts[k] - current_counts[k], 0].max
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
      options = factory_bot_options[k]
      puts "Generating #{count} #{k}..."
      list_args = [options.first, count, options.drop(1)].flatten
      FactoryBot.create_list(*list_args)
    end
  end

  def factory_bot_options
    {
      tournaments: %i[event_scope tournament],
      categories: %i[event_scope category],
      past_events: %i[event with_odds with_event_scopes],
      live_events: %i[event with_odds with_event_scopes live],
      upcoming_events: %i[event with_odds with_event_scopes upcoming],
      entries: %i[entry],
      bets: %i[bet accepted],
      customers: %i[customer ready_to_bet with_address]
    }
  end

  def current_counts
    {
      tournaments: EventScope.where(kind: EventScope::TOURNAMENT).count,
      categories: EventScope.where(kind: EventScope::CATEGORY).count,
      past_events: Event.past.count,
      live_events: Event.in_play.count,
      upcoming_events: Event.upcoming.count,
      entries: Entry.count,
      bets: Bet.count,
      customers: Wallet.pluck(:customer_id).uniq.count
    }
  end
end
