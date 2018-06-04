class EntryRequest < ApplicationRecord
  enum status: {
    pending: 0
  }

  validates :status, inclusion: { in: statuses.keys }
end
