class TransactionsController < ApplicationController
  def index
    @filter = EntryRequestsFilter.new(
      source: EntryRequest.transactions.includes(:entries),
      query_params: query_params(:entry_requests),
      page: params[:page],
      per_page: 20
    )
  end
end
