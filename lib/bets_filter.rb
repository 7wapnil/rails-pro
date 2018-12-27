class BetsFilter
  include DateIntervalFilters

  EXCLUDED_COLUMNS = {
    customers: %i[customer],
    bets: []
  }.freeze

  attr_reader :bets_source

  def initialize(bets_source:, query_params: {}, page: nil)
    @bets_source = bets_source
    @query_params = prepare_interval_filter(query_params, :created_at)
    @page = page
  end

  def sports
    Title.order(:name).pluck(:name)
  end

  def tournaments
    EventScope.order(:name).tournament.pluck(:name)
  end

  def countries
    EventScope.country.order(:name).pluck(:name)
  end

  def search
    @bets_source.includes(:market)
                .with_winnings
                .with_sport
                .with_tournament
                .with_country
                .ransack(@query_params, search_key: :bets)
  end

  def bets
    search.result.order(id: :desc).page(@page)
  end
end
