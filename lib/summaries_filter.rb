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
    pending_bets_amount = pending_bets.pluck(:amount).reduce(:+)
    pending_withdrawals_amount =
      Withdrawal
      .includes(:entry)
      .where(status: :pending)
      .reduce(0) { |sum, w| sum + w.entry.base_currency_amount.to_f }

    @pending = OpenStruct.new(bets_count: pending_bets_count,
                              bets_amount: pending_bets_amount,
                              withdrawals_amount: pending_withdrawals_amount)
  end
end
