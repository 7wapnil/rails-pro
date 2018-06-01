class Transaction < ApplicationRecord
  belongs_to :wallet

  validates :type, presence: true
end
