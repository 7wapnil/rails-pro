class AuditLogContext
  include Mongoid::Document
  include ActiveModel::Validations
  include Mongoid::Attributes::Dynamic

  embedded_in :audit_log

  field :target_id, type: Integer

  def updates
    self[:updates]
  end

  def updates=(value)
    self[:updates] = value
                     .slice!(:created_at,
                             :updated_at,
                             :deleted_at,
                             :last_sign_in_ip,
                             :current_sign_in_ip,
                             :encrypted_password)
  end
end
