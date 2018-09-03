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
  validates_with MarketStateValidator, restrictions: [
    %i[active settled],
    %i[active cancelled],
    %i[inactive suspended],
    %i[inactive cancelled],
    %i[suspended settled],
    %i[suspended cancelled],
    %i[settled active],
    %i[settled inactive],
    %i[settled suspended],
    %i[cancelled active],
    %i[cancelled inactive],
    %i[cancelled suspended],
    %i[cancelled settled]
  ]
end
