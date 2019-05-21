class Competitor < ApplicationRecord
  include Importable

  conflict_target :external_id
  conflict_updatable :name

  validates :name, :external_id, presence: true

  has_many :competitor_players, dependent: :delete_all
  has_many :players, through: :competitor_players
  has_many :event_competitors
  has_many :events, through: :event_competitors
end
