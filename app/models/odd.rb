class Odd < ApplicationRecord
  belongs_to :market
  has_many :odd_values

  validates :name, :value, presence: true
  validates :value, numericality: { greater_than: 0 }
end
