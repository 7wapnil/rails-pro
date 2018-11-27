module Commentable
  extend ActiveSupport::Concern

  included do
    before_action :set_commentable_resource, only: :create_comment
  end

  def create_comment
    @comment = @commentable_resource.comments.new(comment_params)
    @comment.user = current_user
    if @comment.save
      redirect_to @commentable_resource,
                  notice: t('created', instance: t('attributes.comment'))
    else
      redirect_to @commentable_resource,
                  alert: @comment.errors.full_messages.join('. ')
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:text,
                                    :commentable_type,
                                    :commentable_id,
                                    :user_id)
  end

  def set_commentable_resource
    class_name = controller_name.singularize.camelize
    klass = class_name.safe_constantize
    klass ||= resource_name
    raise "Can't find commentable resource '#{class_name}'!" unless klass

    @commentable_resource = klass.find(params[:id])
  end
end
