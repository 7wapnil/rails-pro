class PrimeGenerator
  def initialize(counts:)
    @counts = counts
  end

  def generate(counts:)
    count_correction!
    hardcoded_prerequisites
    populate_data
  end

  private

  def count_correction!
    @counts.keys.each do |k|
      @counts[k] -= current_counts[k]
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
    @football = Title.find_or_create_by football_attrs

    csgo_attrs = FactoryBot.attributes_for :title,
                                           name: 'CS:GO',
                                           kind: Title::ESPORTS
    @cs_go = Title.find_or_create_by csgo_attrs
  end

  def producers
    puts 'Generating producers...'
    live = FactoryBot.build :liveodds_producer, :healthy
    live.save

    prematch = FactoryBot.build :prematch_producer, :healthy
    prematch.save
  end

  def populate_data
    @counts.keys.each do |k|
      next if @counts[k].negative?

      count = @counts[k]
      options = factory_list_options(count)[k]
      puts "Generating #{count} #{k}..."
      FactoryBot.create_list *options
    end
  end

  def factory_list_options(count)
    {
      tournaments: [:event_scope, count, :tournament],
      categories: [:event_scope, count, :category],
      past_events: [:event, count, :with_odds], # past
      live_events: [:event, count, :with_odds, :live],
      upcoming_events: [:event, count, :with_odds, :upcoming],
      entries: [:entry, count],
      bets: [:bet, count, :accepted],
      customers: [:customer, count, :ready_to_bet, :with_address]
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
      customers: Wallet.joins(:customer).count
    }
  end
end
