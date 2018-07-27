class Market < ApplicationRecord
  belongs_to :event
  has_many :odds

  STATUSES = {
    inactive: 0,
    active: 1,
    suspended: 2,
    cancelled: 3,
    settled: 4,
    handed_over: 5
  }.freeze

  DEFAULT_STATUS = STATUSES[:active]

  validates :name, :priority, :status, presence: true
end
