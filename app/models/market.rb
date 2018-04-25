class Market < ApplicationRecord
  belongs_to :event
  has_many :odds
end
