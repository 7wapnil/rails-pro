# frozen_string_literal: true

module Payments
  module Withdrawals
    module Customers
      module Methods
        class EcoPayzForm < WithdrawalMethodForm
          attr_accessor :name, :user_payment_option_id

          validates :name, :user_payment_option_id, presence: true

          def identifier
            :user_payment_option_id
          end

          def consistency_error_message
            I18n.t('errors.messages.payments.withdrawals.eco_payz.inconsistent')
          end
        end
      end
    end
  end
end
