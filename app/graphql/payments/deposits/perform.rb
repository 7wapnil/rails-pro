# frozen_string_literal: true

module Payments
  module Deposits
    class Perform < ::Payments::Action
      type ::Payments::DepositType
      description 'Process deposit request'

      argument :input, Inputs::DepositInput

      private

      def perform_transaction(input)
        transaction = ::Payments::Transactions::Deposit.new(
          method: input[:paymentMethod],
          customer: current_customer,
          currency_code: input[:currencyCode],
          amount: input[:amount].to_d,
          bonus_code: input[:bonusCode]
        )
        currency = transaction.currency

        return CoinsPaid::Deposit.call(transaction) unless currency.fiat?

        ::Payments::Deposit.call(transaction)
      end

      def successful_payment_response
        OpenStruct.new(
          url: transaction_result,
          message: I18n.t('payments.deposits.success_message')
        )
      end
    end
  end
end
