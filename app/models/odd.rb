class Odd < ApplicationRecord
  belongs_to :market

  validates :name, :value, :status, presence: true
  validates :value, numericality: { greater_than: 0 }
end
