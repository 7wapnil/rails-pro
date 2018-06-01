class Balance < ApplicationRecord
  belongs_to :wallet

  validates :type, presence: true
end
