# frozen_string_literal: true

class Deposit < CustomerTransaction
  belongs_to :customer_bonus, optional: true

  has_one :entry_request, as: :origin
  has_one :entry, as: :origin
end
