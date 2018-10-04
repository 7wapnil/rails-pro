class EventsController < ApplicationController
  def index
    @search = Event.search(query_params)
    @events = @search.result.page(params[:page])
  end

  def show
    @event = Event.find(params.require(:id))
  end
end
