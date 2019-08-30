# frozen_string_literal: true

class BetsFilter
  include DateIntervalFilters

  EXCLUDED_COLUMNS = {
    customers: %i[customer],
    bets: []
  }.freeze

  attr_reader :source

  def initialize(source:, query_params: {}, page: nil)
    @source = source
    @query_params = prepare_interval_filter(query_params, :created_at)
    @page = page
  end

  def sports
    TitleDecorator.decorate_collection(Title.ordered_by_name)
                  .map { |t| [t.name, t.id] }
  end

  def tournaments
    EventScope.order(:name).tournament.pluck(:name)
  end

  def categories
    EventScope.category.order(:name).pluck(:name)
  end

  def search
    @source.includes(:market)
           .with_winning_amount
           .with_sport
           .with_tournament
           .with_category
           .ransack(@query_params, search_key: :bets)
  end

  def bets
    BetDecorator.decorate_collection(
      search.result.order(id: :desc).page(@page)
    )
  end
end
