class BetsController < ApplicationController
  include DateIntervalFilters

  def index
    query = prepare_interval_filter(query_params, :created_at)
    @filter = BetsFilter.new(bets_source: Bet,
                             query: query,
                             page: params[:page])
  end

  def show
    @bet = Bet
           .includes(%i[currency customer odd])
           .with_winnings
           .find(params[:id])
  end
end
