class BetsController < ApplicationController
  include DateIntervalFilters

  def index
    @search = Bet.with_winnings
                 .search(prepare_interval_filter(query_params, :created_at))

    @bets = @search.result.page(params[:page])
  end

  def show
    @bet = Bet
           .includes(%i[currency customer odd])
           .with_winnings
           .find(params[:id])
  end
end
