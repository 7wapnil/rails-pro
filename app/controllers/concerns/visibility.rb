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
    klass = controller_name.singularize.capitalize.constantize
    @visible_resource = klass.find(params[:id])
  end
end
