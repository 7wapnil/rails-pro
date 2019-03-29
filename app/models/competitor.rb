class Competitor < ApplicationRecord
  validates :name, :external_id, presence: true
end
