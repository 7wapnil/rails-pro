module EntryRequests
  module Factories
    class Withdrawal < ApplicationService
      def initialize(wallet:, amount:, mode:, **attrs)
        @wallet = wallet
        @amount = amount
        @mode = mode
        @comment = attrs[:comment]
        @initiator = attrs[:initiator] || wallet.customer
        @origin = attrs[:origin]
      end

      def call
        create_entry_request!
        verify_withdrawal!
        create_balance_entry_request!
        entry_request
      rescue Withdrawals::WithdrawalError => e
        entry_request.register_failure!(e.message)
        entry_request
      end

      private

      attr_reader :wallet, :mode, :entry_request, :comment, :initiator

      def amount
        -@amount.abs
      end

      def create_entry_request!
        @entry_request = EntryRequest.create!(
          kind: EntryRequest::WITHDRAW,
          currency: wallet.currency,
          customer: wallet.customer,
          amount: amount,
          initiator: wallet.customer,
          mode: mode,
          comment: comment
        )
      end

      def verify_withdrawal!
        Withdrawals::WithdrawalVerification.call(wallet, amount)
      end

      def create_balance_entry_request!
        BalanceRequestBuilders::Withdrawal.call(entry_request,
                                                real_money: amount)
      end
    end
  end
end
