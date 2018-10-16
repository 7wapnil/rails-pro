class MarketsController < ApplicationController
  def update
    market = Market.find(params[:id])
    updated = market.update(market_params)
    render nothing: true, status: :unprocessable_entity unless updated
  end

  private

  def market_params
    # add more attributes if you need
    params.require(:market).permit(:priority)
  end
end
