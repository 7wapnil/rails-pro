class SummariesFilter
  include DateIntervalFilters

  attr_reader :source, :query_params

  def initialize(source:, query_params: {})
    @source = source
    @query_params = prepare_interval_filter(query_params, :day)
  end

  def search
    @source.ransack(@query_params, search_key: :customer_summaries)
  end

  def summaries
    search.result.decorate
  end

  def pending
    return @pending if @pending

    pending_bets = Bet.pending
    pending_bets_count = pending_bets.count
    pending_bets_amount = pending_bets.pluck(:amount).reduce(:+) || 0.0

    pending_withdrawals_amount = Withdrawals::PendingAmount.call

    @pending = OpenStruct.new(bets_count: pending_bets_count,
                              bets_amount: pending_bets_amount,
                              withdrawals_amount: pending_withdrawals_amount)
  end

  def balance_totals
    return @balance_totals if @balance_totals

    totals_by_kind = BalanceCalculations::Totals.call

    @balance_totals = OpenStruct.new(
      totals_by_kind.merge(total: totals_by_kind.values.sum)
    )
  end
end