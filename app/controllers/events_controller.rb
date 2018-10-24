class EventsController < ApplicationController
  include Visibility

  def index
    @search = Event.order(start_at: :desc).search(query_params)
    @events = @search.result.page(params[:page])
    @sports = Title.pluck(:name)
  end

  def show
    @event = Event.find(params.require(:id))
    @labels = Label.all
  end

  def update
    @event = Event.find(params[:id])
    updated = @event.update(event_params)

    render nothing: true, status: :unprocessable_entity unless updated
  end

  def update_labels
    @event = Event.find(params[:id])
    if labels_params[:ids].include? '0'
      @event.labels.clear
    else
      @event.label_ids = labels_params[:ids]
    end
  end

  private

  def labels_params
    params.require(:labels).permit(ids: [])
  end

  def event_params
    params.require(:event).permit(:priority)
  end
end
