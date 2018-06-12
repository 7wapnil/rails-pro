class Entry < ApplicationRecord
  default_scope { order(created_at: :desc) }

  include EntryKinds

  belongs_to :wallet
  has_many :balance_entries

  validates :kind, :amount, presence: true
  validates :kind, inclusion: { in: kinds.keys }
end
