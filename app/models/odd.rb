class Odd < ApplicationRecord
  enum status: {
    inactive: 0,
    active: 1
  }

  belongs_to :market

  validates :name, :value, :status, presence: true
  validates :value, numericality: { greater_than: 0 }
end
