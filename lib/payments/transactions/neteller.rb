module Payments
  module Transactions
    class Neteller < ::Payments::Transaction
      validates :holder_name, :last_four_digits, presence: true
      validates :holder_name, length: { maximum: MAX_HOLDER_NAME_LENGTH }
      validates :last_four_digits, numericality: true,
                                   length: { is: DIGITS_LENGTH }

      def deposit_provider
        ::Payments::SafeCharge::Provider.new
      end
    end
  end
end
