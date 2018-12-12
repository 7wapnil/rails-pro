class BetsFilter
  EXCLUDED_COLUMNS = {
    customers: %i[customer],
    bets: []
  }.freeze

  attr_reader :bets_source

  def initialize(bets_source:, query: {}, page: nil)
    @bets_source = bets_source
    @query_params = query
    @page = page
  end

  def sports
    @sports ||= Title.order(:name).pluck(:name)
  end

  def tournaments
    @tournaments ||= EventScope.order(:name).tournament.pluck(:name)
  end

  def countries
    @countries ||= EventScope.country.order(:name).pluck(:name)
  end

  def search
    @search ||= bets_source.includes(:market)
                           .with_winnings
                           .with_sport
                           .with_tournament
                           .with_country
                           .ransack(@query_params)
  end

  def bets
    @bets ||= search.result.order(id: :desc).page(@page)
  end
end
