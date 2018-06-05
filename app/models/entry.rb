class Entry < ApplicationRecord
  include EntryKinds

  belongs_to :wallet
  has_many :balance_entries

  validates :kind, :amount, presence: true
  validates :kind, inclusion: { in: kinds.keys }
end
