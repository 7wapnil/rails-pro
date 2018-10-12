module Visibility
  extend ActiveSupport::Concern

  included do
    before_action :set_visible_resource, only: :update_visibility
  end

  def update_visibility
    @visible_resource.update(visible: params[:visible])
  end

  private

  def set_visible_resource
    klass = controller_name.singularize
    @visible_resource ||= klass.capitalize.constantize.find(params[:id])
  end
end
