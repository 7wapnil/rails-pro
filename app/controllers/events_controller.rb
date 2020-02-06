class EventsController < ApplicationController
  include Labelable
  include DateIntervalFilters

  find :event, only: :update, friendly: true

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
    @event = Event.includes(:labels, :event_scopes, :title, markets: [:labels])
                  .order('markets.priority ASC, markets.name ASC')
                  .friendly
                  .find(params.require(:id))
                  .decorate

    @labels = Label.where(kind: Label::EVENT)
    @market_labels = Label.where(kind: Label::MARKET)
  end

  def update
    result = @event.update(event_params)

    return head :unprocessable_entity unless result

    WebSocket::Client.instance.trigger_event_update(@event, force: true)

    respond_to do |format|
      format.js
      format.html { redirect_to events_path }
    end
  end

  private

  def event_params
    params.require(:event).permit(
      :slug,
      :priority,
      :visible,
      :twitch_url,
      :twitch_start_time,
      :twitch_end_time
    )
  end
end
