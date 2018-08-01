class Market < ApplicationRecord
  STATUSES = {
    inactive: 0,
    active: 1,
    suspended: 2,
    cancelled: 3,
    settled: 4,
    handed_over: 5
  }.freeze

  DEFAULT_STATUS = STATUSES[:active]

  enum status: STATUSES

  belongs_to :event
  has_many :odds

  validates :name, :priority, :status, presence: true
end
