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
    class_name = controller_name.singularize.camelize
    klass = class_name.safe_constantize
    raise "Can't find visible resource '#{class_name}'!" unless klass

    @visible_resource = klass.find(params[:id])
  end
end