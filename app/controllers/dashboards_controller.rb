class DashboardsController < ApplicationController
  BETS_LIMIT = 3

  def index
    @bets_filter = BetsFilter.new(bets_source: Bet,
                                  query_params: params[:bets] || {},
                                  page: params[:page])
  end
end
