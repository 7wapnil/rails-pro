class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_validation :log_errors, if: proc { |m| m.errors }

  def loggable_attributes
    attributes
      .symbolize_keys
      .slice!(:id,
              :created_at,
              :updated_at,
              :deleted_at,
              :last_sign_in_ip,
              :current_sign_in_ip,
              :encrypted_password)
      .merge(target_id: id, target_class: self.class.name)
  end

  def log_errors
    return unless errors.any?
    Rails.logger.info "#{self.class}: #{errors.full_messages.join("\n")}"
  end
end
