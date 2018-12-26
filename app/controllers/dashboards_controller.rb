class DashboardsController < ApplicationController
  BETS_LIMIT = 3

  def index
    @bets_filter = BetsFilter.new(
      bets_source: Bet,
      query_params: query_params(:bets),
      page: params[:page]
    )
    @customers_filter = CustomersFilter.new(
      customers_source: Customer,
      query_params: query_params(:customers),
      page: params[:page]
    )
  end
end
