class Event < ApplicationRecord
  belongs_to :discipline
  has_many :markets

  validates :name, presence: true
end
