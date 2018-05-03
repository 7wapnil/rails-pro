class Market < ApplicationRecord
  belongs_to :event
  has_many :odds

  validates :name, :priority, presence: true
end
