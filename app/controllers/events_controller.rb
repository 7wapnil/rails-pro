class EventsController < ApplicationController
  include Visibility
  include Labelable

  def index
    @search = Event.includes(:labels)
                   .with_markets_count
                   .with_wager
                   .with_bets_count
                   .search(query_params)

    @events = @search.result.order(start_at: :desc).page(params[:page])
    @sports = Title.pluck(:name)
  end

  def show
    @event = Event.includes(:labels, :event_scopes, :title, markets: [:labels])
                  .order('markets.priority ASC, markets.name ASC')
                  .find(params.require(:id))

    @labels = Label.where(kind: :event)
    @market_labels = Label.where(kind: :market)
  end

  def update
    @event = Event.find(params[:id])
    updated = @event.update(event_params)

    render nothing: true, status: :unprocessable_entity unless updated
  end

  private

  def event_params
    params.require(:event).permit(:priority)
  end
end
