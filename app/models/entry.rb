class Entry < ApplicationRecord
  include EntryKinds

  belongs_to :wallet
  has_one :currency, through: :wallet
  has_many :balance_entries

  validates :amount, presence: true
  validates :kind, inclusion: { in: kinds.keys }

  validates_with EntryAmountValidator
end
