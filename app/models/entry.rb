class Entry < ApplicationRecord
  belongs_to :wallet
  has_many :balance_entries

  validates :type, :amount, presence: true
end
