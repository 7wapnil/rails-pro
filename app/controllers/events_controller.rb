class EventsController < ApplicationController
  include Visibility
  include Labelable
  include DateIntervalFilters

  def index
    @search = Event.includes(:labels, :event_scopes)
                   .with_markets_count
                   .with_wager
                   .with_bets_count
                   .ransack(prepare_interval_filter(query_params, :start_at))

    @events = EventDecorator.decorate_collection(
      @search.result.order(start_at: :asc).page(params[:page])
    )

    @sports = TitleDecorator.decorate_collection(Title.ordered_by_name)
                            .map { |t| [t.name, t.id] }
  end

  def show
    @event =
      Event.includes(:labels, :event_scopes, :title, markets: [:labels])
           .order('markets.priority ASC, markets.name ASC')
           .find(params.require(:id))
           .decorate

    @labels = Label.where(kind: Label::EVENT)
    @market_labels = Label.where(kind: Label::MARKET)
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
