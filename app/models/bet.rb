class Bet < ApplicationRecord
  enum status: {
    pending: 0,
    succeeded: 1,
    failed: 2,
    settled: 3
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
  validates :result, inclusion: { in: [true, false] }
  validates :void_factor,
            numericality: {
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: 1
            },
            allow_nil: true

  delegate :market, to: :odd
end
