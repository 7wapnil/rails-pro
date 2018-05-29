class Label < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2 }

  has_and_belongs_to_many :customers
end
