class ArchivedEventScope
  include Mongoid::Document

  embedded_in :archived_event

  field :name, type: String
  field :external_id, type: String
  field :kind, type: String
end
