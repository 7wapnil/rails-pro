class BetsController < ApplicationController
  def index
    @filter = BetsFilter.new(bets_source: Bet,
                             query_params: query_params(:bets),
                             page: params[:page])
  end

  def show
    @bet = Bet
           .includes(%i[currency customer odd])
           .with_winnings
           .find(params[:id])
  end
end
