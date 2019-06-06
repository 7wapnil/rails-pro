# frozen_string_literal: true

module Payments
  module Withdrawals
    class Perform < ::Base::Resolver
      type !types.Boolean
      description 'Create withdrawal request'

      argument :input, Inputs::WithdrawInput

      def resolve(_obj, args)
        input = args['input']

        raise '`input` has to be passed' unless input

        withdrawal_data = input.to_h
        withdrawal_data[:customer] = current_customer
        Forms::WithdrawRequest.new(withdrawal_data).validate!

        withdrawal_request = create_withdrawal_request!(input)
        EntryRequests::WithdrawalWorker
          .perform_async(withdrawal_request.entry_request.id)

        true
      end

      private

      def create_withdrawal_request!(args)
        wallet = current_customer.wallets.find(args['walletId'])
        WithdrawalRequests::Create
          .call(wallet: wallet,
                payload: args['paymentDetails'],
                payment_method: args['paymentMethod'],
                amount: args['amount'])
      end
    end
  end
end
