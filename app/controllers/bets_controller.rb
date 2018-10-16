class BetsController < ApplicationController
  def index
    @search = Bet.search(query_params)
    @bets = @search.result.page(params[:page])
  end

  def show
    @bet = Bet.find(params[:id])
  end
end
