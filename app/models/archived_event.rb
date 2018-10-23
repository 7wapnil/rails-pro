class ArchivedEvent
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  default_scope { order(created_at: :desc) }

  embeds_many :scopes,
              class_name: 'ArchivedEventScope',
              inverse_of: :archived_event

  field :external_id, type: String
  field :name, type: String
  field :description, type: String
  field :start_at, type: DateTime
  field :payload, type: Hash
end
