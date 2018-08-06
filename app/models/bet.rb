class Bet < ApplicationRecord
  enum status: {
    pending: 0,
    succeeded: 1,
    failed: 2
  }

  belongs_to :customer
  belongs_to :odd
  belongs_to :currency
end
