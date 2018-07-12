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
end
