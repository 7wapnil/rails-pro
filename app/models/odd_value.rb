class OddValue < ApplicationRecord
  belongs_to :odd

  validates :value, presence: true
end
