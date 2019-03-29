class Player < ApplicationRecord
  validates :name, :external_id, presence: true
end
