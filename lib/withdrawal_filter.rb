class WithdrawalFilter
  attr_reader :source, :query_params

  def initialize(source:, query_params: {}, page: nil)
    @source = source
    @query_params = query_params
    @page = page
  end

  def statuses
    Withdrawal.statuses
  end

  def payment_methods
    EntryRequest.modes
  end

  def search
    @source.ransack(@query_params, search_key: :withdrawals)
  end

  def withdrawals
    search.result.order(id: :desc).page(@page)
  end
end
