class Market < ApplicationRecord
  before_validation :define_priority, if: :name_changed?

  PRIORITIES_MAP = [
    { pattern: /^Match winner/, priority: 1 }
  ].freeze

  DEFAULT_PRIORITY = 0

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

  def define_priority
    matched = PRIORITIES_MAP.detect do |rule|
      name =~ rule[:pattern]
    end

    self.priority = matched ? matched[:priority] : DEFAULT_PRIORITY
  end
end
