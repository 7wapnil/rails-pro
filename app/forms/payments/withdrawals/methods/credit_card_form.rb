# frozen_string_literal: true

module Payments
  module Withdrawals
    module Methods
      class CreditCardForm
        include ActiveModel::Model

        DIGITS_LENGTH = 4
        MAX_HOLDER_NAME_LENGTH = 100

        attr_accessor :holder_name, :last_four_digits

        validates :holder_name, :last_four_digits, presence: true
        validates :holder_name, length: { maximum: MAX_HOLDER_NAME_LENGTH }
        validates :last_four_digits, numericality: true,
                                     length: { is: DIGITS_LENGTH }
      end
    end
  end
end
