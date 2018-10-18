class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_validation :log_errors, if: proc { |m| m.errors }

  def log_errors
    return unless errors.any?

    Rails.logger.warn "#{self.class}: #{errors.full_messages.join("\n")}"
  end
end
