class Competitor < ApplicationRecord
  validates :name, :external_id, presence: true

  has_many :competitor_players, dependent: :delete_all
  has_many :players, through: :competitor_players
end
