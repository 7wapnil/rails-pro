class AuditLog
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  field :target, type: String
  field :action, type: String
  field :origin, type: Hash
  field :payload, type: Hash
end
