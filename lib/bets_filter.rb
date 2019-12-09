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
    @search ||= @source.joins(join_bet_search_relations)
                       .group('bets.id')
                       .includes(
                         :customer,
                         :currency,
                         scoped_bet_legs: %i[market event]
                       )
                       .ransack(formatted_query_params, search_key: :bets)
  end

  def bets
    @bets ||= BetDecorator.decorate_collection(
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

  def join_bet_search_relations
    <<~SQL
      INNER JOIN (#{bet_leg_with_relations_sql}) scoped_bet_legs ON
        scoped_bet_legs.bet_id = bets.id
    SQL
  end

  def bet_leg_with_relations_sql
    BetLeg.select('bet_legs.*')
          .with_category
          .with_tournament
          .with_sport
          .to_sql
  end
end
