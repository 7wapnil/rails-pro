class MarketsController < ApplicationController
  include Visibility
  include Labelable

  def update
    market = Market.find(params[:id])
    updated = market.update(market_params)
    render nothing: true, status: :unprocessable_entity unless updated
  end

  private

  def market_params
    params.require(:market).permit(:priority)
  end
end
