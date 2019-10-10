# frozen_string_literal: true

class BetsFilter
  include DateIntervalFilters

  EXCLUDED_COLUMNS = {
    customers: %i[customer],
    bets: []
  }.freeze
  NO_SETTLEMENT_STATUS = 'no_status'
  SETTLEMENT_STATUSES = [
    NO_SETTLEMENT_STATUS,
    *Bet::BET_SETTLEMENT_STATUSES.values
  ].freeze
  STATUSES = Bet::BET_STATUSES.values

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
           .ransack(formatted_query_params, search_key: :bets)
  end

  def bets
    BetDecorator.decorate_collection(
      search.result.order(id: :desc).page(@page)
    )
  end

  def search_params(key)
    @query_params.dig(key)
  end

  private

  def formatted_query_params
    return @query_params unless without_settlement_status?

    @query_params[:settlement_status_null] = true
    @query_params.except(:settlement_status_eq)
  end

  def without_settlement_status?
    @query_params[:settlement_status_eq] == NO_SETTLEMENT_STATUS
  end
end
