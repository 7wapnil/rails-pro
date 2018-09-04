class Market < ApplicationRecord
  before_validation :define_priority, if: :name_changed?

  PRIORITIES_MAP = [
    [
      /^Match winner/
    ], # First priority
    [] # Second priority
  ].freeze

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

  def define_priority
    self.priority = 0
    PRIORITIES_MAP.each_with_index do |regex_map, index|
      regex_map.each do |regex|
        next if name.scan(regex).empty?
        self.priority = index + 1
        break
      end
    end
  end
end
