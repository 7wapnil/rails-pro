class Entry < ApplicationRecord
  include EntryTypes

  belongs_to :wallet
  has_many :balance_entries

  validates :type, :amount, presence: true
  validates :type, inclusion: { in: types.keys }
end
