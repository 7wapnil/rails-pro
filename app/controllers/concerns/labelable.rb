module Labelable

  extend ActiveSupport::Concern

  included do
    before_action :set_labelable_resource, only: :update_labels
  end

  def update_labels
    if labels_params[:ids].include? '0'
      @labelable_resource.labels.clear
    else
      @labelable_resource.label_ids = labels_params[:ids]
    end
  end

  private


  def labels_params
    params.require(:labels).permit(ids: [])
  end

  def set_labelable_resource
    class_name = controller_name.singularize.camelize
    klass = class_name.safe_constantize
    raise "Can't find labelable resource '#{class_name}'!" unless klass

    @labelable_resource = klass.find(params[:id])
  end
end
