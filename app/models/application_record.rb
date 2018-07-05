class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  attr_writer :origin_kind, :origin_id

  after_create do
    log_event :created
  end

  after_update do
    log_event :updated
  end

  after_destroy do
    log_event :destroyed
  end

  private

  def log_event(action)
  end
end
