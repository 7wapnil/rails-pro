class MarketTemplate < ApplicationRecord
  validates :external_id, :name, presence: true
end
