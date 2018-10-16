class AuditLog
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include ActiveModel::Validations

  default_scope { order(created_at: :desc) }

  embeds_one :context, class_name: 'AuditLogContext', inverse_of: :audit_log

  field :event, type: String
  field :user_id, type: Integer
  field :customer_id, type: Integer

  validates :event, presence: true

  def user
    @user ||= User.find_by(id: user_id)
  end

  def user_name
    user&.full_name
  end

  def customer
    @customer ||= Customer.find_by(id: customer_id)
  end

  def customer_name
    customer&.full_name
  end

  def interpolation
    attributes = { user_name: user_name,
                   customer_name: customer_name }
    return attributes unless context
    attributes.merge(context.attributes.symbolize_keys)
  end
end
