class Odd < ApplicationRecord
  belongs_to :market
  has_many :odd_values

  validates :name, presence: true
end
