class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # if events must be stored to audit logs collection
  def auditable?
    true
  end

  attr_accessor :origin_kind, :origin_id

  after_create do
    log_event :created, id: id, changes: filter_changes
  end

  after_update do
    log_event :updated, id: id, changes: filter_changes
  end

  after_destroy do
    log_event :destroyed, id: id
  end

  def log_event(action, payload)
    return unless auditable?
    Audit::Service.call(target: self.class,
                        action: action,
                        origin_kind: origin_kind,
                        origin_id: origin_id,
                        payload: payload)
  end

  private

  def filter_changes
    previous_changes.slice!(:created_at,
                            :updated_at,
                            :encrypted_password)
  end
end
