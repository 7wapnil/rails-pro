class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

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
      .merge(target_id: id)
  end
end
