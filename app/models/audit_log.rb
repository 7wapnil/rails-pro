class AuditLog
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include ActiveModel::Validations

  default_scope { order(created_at: :desc) }

  embeds_one :context, class_name: 'AuditLogContext', inverse_of: :audit_log

  field :event, type: String
  field :origin_kind, type: String
  field :origin_id, type: Integer

  validates :event,
            :origin_kind,
            :origin_id,
            presence: true

  def origin
    self[:origin_kind]
      .to_s
      .camelize
      .constantize
      .find_by(id: self[:origin_id])
  end

  def origin_name
    origin&.full_name
  end

  def target
    return nil unless self[:context][:target_class]
    self[:context][:target_class]
      .to_s
      .camelize
      .constantize
      .find_by(id: self[:context][:target_id])
  end

  def interpolation
    {
      origin_id: origin_id,
      origin_kind: origin_kind,
      origin_name: origin_name,
      target: target
    }.merge(context.attributes.symbolize_keys)
  end
end
