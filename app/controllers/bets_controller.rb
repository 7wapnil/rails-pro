class BetsController < ApplicationController
  def index
    @filter = BetsFilter.new(source: Bet,
                             query_params: query_params(:bets),
                             page: params[:page])
  end

  def show
    @bet = Bet
           .includes(%i[currency customer odd])
           .with_winning_amount
           .find(params[:id])
  end
end
