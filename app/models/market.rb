class Market < ApplicationRecord
  belongs_to :event
  has_many :odds

  validates :name, :priority, :status, presence: true
end
