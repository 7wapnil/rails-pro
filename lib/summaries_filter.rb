class SummariesFilter
  include DateIntervalFilters

  attr_reader :source, :query_params, :search_params

  def initialize(source:, query_params: {})
    @source = source
    @query_params = query_params
    @search_params = decorated_query_params
  end

  def search
    @source.ransack(search_params, search_key: :customer_summaries)
  end

  def summaries
    @summaries ||= search.result.decorate
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

  def custom_interval?
    query_params
      .slice(:day_gteq, :day_lteq)
      .values
      .any?(&:present?)
  end

  private

  def decorated_query_params
    prepare_interval_filter(
      query_params.reverse_merge(default_daterenge),
      :day
    )
  end

  def default_daterenge
    return {} if custom_interval?

    {
      day_gteq: Time.zone.now,
      day_lteq: Time.zone.now
    }
  end
end
