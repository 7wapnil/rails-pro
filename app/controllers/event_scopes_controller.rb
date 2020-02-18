# frozen_string_literal: true

class EventScopesController < ApplicationController
  protect_from_forgery prepend: true

  find :title, by: :title_id, only: :index
  find :event_scope, only: %i[edit update], friendly: true

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

  def update
    result = @event_scope.update(update_params)

    return render :edit unless result

    redirect_to edit_event_scope_path(@event_scope),
                notice: t('.success_message')
  end

  private

  def update_params
    params.require(:event_scope).permit(:slug, :meta_title, :meta_description)
  end
end
