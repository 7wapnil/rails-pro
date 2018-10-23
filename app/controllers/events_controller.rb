class EventsController < ApplicationController
  def index
    @search = base_query.search(query_params)
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

  def base_query
    scope = Event.order(start_at: :desc)
    sorting_query = query_params[:s]
    is_string = sorting_query.is_a?(String)
    return scope unless is_string && sorting_query.starts_with?('markets_count')

    scope.with_markets_count
  end
end
