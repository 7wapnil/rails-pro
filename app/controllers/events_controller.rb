class EventsController < ApplicationController
  def index
    @search = Event.order(start_at: :desc).search(query_params)
    @events = @search.result.page(params[:page])
    @sports = Title.pluck(:name)
  end

  def show
    @event = Event.find(params.require(:id))
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
