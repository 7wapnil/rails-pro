class Entry < ApplicationRecord
  default_scope { order(created_at: :desc) }

  include EntryKinds

  belongs_to :wallet
  belongs_to :origin, polymorphic: true, optional: true
  has_one :currency, through: :wallet
  has_many :balance_entries

  validates :amount, presence: true
  validates :kind, inclusion: { in: kinds.keys }

  validates_with EntryAmountValidator
end
