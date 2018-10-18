class BetsController < ApplicationController
  def index
    @search = Bet.with_settlement_and_winnings.search(query_params)
    @bets = @search.result.page(params[:page])
  end

  def show
    @bet = Bet.includes(%i[currency odd]).find(params[:id])
  end
end
