class ArchivedEvent
  include Mongoid::Document
  include Mongoid::Timestamps::Created

  default_scope { order(created_at: :desc) }

  embeds_many :scopes,
              class_name: ArchivedEventScope.name,
              inverse_of: :archived_event

  field :external_id, type: String
  field :name, type: String
  field :title_name, type: String
  field :description, type: String
  field :start_at, type: DateTime
  field :display_status, type: String
  field :home_score, type: Integer
  field :away_score, type: Integer
  field :time_in_seconds, type: Integer
  field :liveodds, type: String

  index({ external_id: 1 }, unique: true, name: 'external_id_index')
end
