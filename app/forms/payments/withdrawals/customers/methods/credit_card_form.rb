# frozen_string_literal: true

module Payments
  module Withdrawals
    module Customers
      module Methods
        class CreditCardForm < WithdrawalMethodForm
          DIGITS_LENGTH = 4
          MAX_HOLDER_NAME_LENGTH = 100

          attr_accessor :holder_name, :masked_account_number, :token_id

          validates :holder_name,
                    :masked_account_number,
                    :token_id,
                    presence: true
          validates :holder_name, length: { maximum: MAX_HOLDER_NAME_LENGTH }

          def identifier
            :masked_account_number
          end

          def consistency_error_message
            I18n.t(
              'errors.messages.payments.withdrawals.credit_card.inconsistent'
            )
          end
        end
      end
    end
  end
end
