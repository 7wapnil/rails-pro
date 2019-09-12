module Visibility
  extend ActiveSupport::Concern

  included do
    before_action :set_visible_resource, only: :update_visibility
    after_action :stream_resource_visibility, only: :update_visibility
  end

  def update_visibility
    @visible_resource.update(visible: params[:visible])
  end

  private

  def set_visible_resource
    class_name = controller_name.singularize.camelize
    klass = class_name.safe_constantize
    raise "Can't find visible resource '#{class_name}'!" unless klass

    @visible_resource = klass.find(params[:id])
  end

  def stream_resource_visibility
    case @visible_resource
    when Market
      WebSocket::Client.instance.trigger_event_update(
        @visible_resource.event,
        force: @visible_resource.active? && @visible_resource.event.active?
      )
    when Event
      WebSocket::Client.instance.trigger_event_update(
        @visible_resource,
        force: @visible_resource.active?
      )
    end
  end
end
