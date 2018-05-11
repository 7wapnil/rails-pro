class OddValue < ApplicationRecord
  default_scope { order(created_at: :desc) }

  belongs_to :odd

  validates :value, presence: true
end
