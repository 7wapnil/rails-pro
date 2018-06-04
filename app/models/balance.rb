class Balance < ApplicationRecord
  belongs_to :wallet
  has_many :balance_entries

  validates :type, presence: true
end
