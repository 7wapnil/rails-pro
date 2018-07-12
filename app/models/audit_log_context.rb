class AuditLogContext
  include Mongoid::Document
  include ActiveModel::Validations

  embedded_in :audit_log

  field :updates, type: Hash
  field :customer_id, type: Integer

  validates :customer_id, numericality: true
end
