class Balance < ApplicationRecord
  belongs_to :wallet
  has_many :balance_entries

  validates :kind, presence: true

  enum kind: {
    real_money: 0,
    bonus: 1
  }
end
