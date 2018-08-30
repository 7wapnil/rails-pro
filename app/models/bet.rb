class Bet < ApplicationRecord
  enum status: {
    pending: 0,
    succeeded: 1,
    failed: 2,
    cancelled: 3
  }

  belongs_to :customer
  belongs_to :odd
  belongs_to :currency

  has_one :entry, as: :origin
  has_one :entry_request, as: :origin

  validates :odd_value,
            numericality: {
              equal_to: ->(bet) { bet.odd.value },
              on: :create
            }

  delegate :market, to: :odd
end
