class EventScopesController < ApplicationController
  protect_from_forgery prepend: true

  def index
    @title = Title.find(params[:title_id]).decorate
  end

  def show
    render json: EventScopes::CollectChildren.call(
      params[:title_id],
      params[:event_scope_id]
    )
  end

  def create
    EventScopes::Reorder.call(params[:sorted_event_scopes])
  end
end
