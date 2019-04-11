class WithdrawalRequestFilter
  attr_reader :source, :query_params

  def initialize(source:, query_params: {}, page: nil)
    @source = source
    @query_params = query_params
    @page = page
  end

  def statuses
    WithdrawalRequest.statuses
  end

  def payment_methods
    EntryRequest.modes
  end

  def search
    @source.ransack(@query_params, search_key: :withdrawal_requests)
  end

  def withdrawal_requests
    search.result.order(id: :desc).page(@page)
  end
end
