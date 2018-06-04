class Balance < ApplicationRecord
  belongs_to :wallet
  has_many :balance_entries

  validates :type, presence: true

  enum type: {
    real_money: 0,
    bonus: 1
  }
end
