# frozen_string_literal: true

class EventScopesController < ApplicationController
  protect_from_forgery prepend: true

  find :title, by: :title_id, only: :index

  decorates_assigned :title

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
