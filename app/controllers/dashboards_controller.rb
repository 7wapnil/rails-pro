class DashboardsController < ApplicationController
  ENTRY_REQUESTS_LIMIT = 100

  def index
    bets_filter
    customers_filter
    entry_requests_filter
  end

  private

  def bets_filter
    @bets_filter = BetsFilter.new(
      source: Bet,
      query_params: query_params(:bets),
      page: params[:page]
    )
  end

  def customers_filter
    @customers_filter = CustomersFilter.new(
      source: Customer,
      query_params: query_params(:customers),
      page: params[:page]
    )
  end

  def entry_requests_filter
    @entry_requests_filter = EntryRequestsFilter.new(
      source: EntryRequest
              .where('entry_requests.kind IN (?)', EntryKinds::FUND_KINDS.keys)
              .limit(ENTRY_REQUESTS_LIMIT),
      query_params: query_params(:entry_requests),
      page: params[:page]
    )
  end
end
