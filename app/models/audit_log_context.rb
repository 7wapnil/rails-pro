class AuditLogContext
  include Mongoid::Document
  include ActiveModel::Validations
  include Mongoid::Attributes::Dynamic

  embedded_in :audit_log

  def updates
    self[:updates]
  end

  def updates=(record)
    self[:updates] = record
                       .previous_changes
                       .slice!(:created_at,
                                :updated_at,
                                :deleted_at,
                                :last_sign_in_ip,
                                :current_sign_in_ip,
                                :encrypted_password)
  end
end
