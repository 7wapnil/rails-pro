class AuditLog
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include ActiveModel::Validations

  default_scope { order(created_at: :desc) }

  field :target, type: String
  field :action, type: String
  field :origin, type: Hash
  field :payload, type: Hash

  validates :target,
            :action,
            :origin,
            presence: true

  def origin
    return if self[:origin][:kind].blank? && self[:origin][:id].blank?

    self[:origin][:kind]
      .to_s
      .camelize
      .constantize
      .find_by(id: self[:origin][:id])
  end
end
