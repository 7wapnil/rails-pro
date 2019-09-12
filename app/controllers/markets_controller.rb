class MarketsController < ApplicationController
  include Labelable

  find :market, only: :update

  def update
    return head :unprocessable_entity unless @market.update(market_params)

    WebSocket::Client.instance.trigger_event_update(
      @market.event,
      force: @market.active? && @market.event.active?
    )

    respond_to do |format|
      format.js
      format.html do
        redirect_back(fallback_location: events_path)
      end
    end
  end

  private

  def market_params
    params.require(:market).permit(:priority, :visible)
  end
end
