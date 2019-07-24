# frozen_string_literal: true

module Payments
  module Withdrawals
    class Perform < ::Payments::Action
      type !types.String
      description 'Process withdrawal request'

      argument :input, Inputs::WithdrawInput

      private

      def perform_transaction(input)
        transaction = ::Payments::Transactions::Withdrawal.new(
          method: input[:paymentMethod],
          password: input[:password],
          customer: current_customer,
          currency_code: input[:currencyCode],
          amount: input[:amount].to_d,
          details: extract_details(input),
          initiator: current_customer
        )
        ::Payments::Withdraw.call(transaction)
      end

      def extract_details(input)
        input[:paymentDetails].to_a.map { |obj| [obj.code, obj.value] }.to_h
      end

      def successful_payment_response
        I18n.t('payments.withdrawals.success_message')
      end
    end
  end
end
