# frozen_string_literal: true

module Payments
  module Withdrawals
    module Customers
      module Methods
        class SkrillForm < WithdrawalMethodForm
          attr_accessor :email

          validates :email, presence: true

          def identifier
            :email
          end

          def consistency_error_message
            I18n.t('errors.messages.payments.withdrawals.skrill.inconsistent')
          end
        end
      end
    end
  end
end
