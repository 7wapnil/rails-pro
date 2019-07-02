class TransactionsController < ApplicationController
  def index
    filter_source = CustomerTransaction
                    .includes(entry_requests: %i[customer currency])
    @filter = CustomerTransactionsFilter.new(
      source: filter_source,
      query_params: query_params(:customer_transactions),
      page: params[:page],
      per_page: 20
    )
  end
end
