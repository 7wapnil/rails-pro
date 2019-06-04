# frozen_string_literal: true

module Payments
  class PerformWithdrawal < ::Base::Resolver
    type !types.Boolean
    description 'Create withdrawal request'

    # TODO: extract arguments here and remove input type
    argument :input, Inputs::WithdrawInput

    def resolve(_obj, args)
      input = args['input']
      withdrawal_data = input.to_h
      withdrawal_data[:customer] = current_customer
      withdrawal_data[:details] = withdrawal_data.delete(:payment_details)
      Forms::WithdrawRequest.new(withdrawal_data).validate!

      withdrawal = create_withdrawal!(input)
      EntryRequests::WithdrawalWorker
        .perform_async(withdrawal.entry_request.id)

      true
    end

    private

    def create_withdrawal!(args)
      wallet = current_customer.wallets.find(args['walletId'])
      Withdrawals::CreateService
        .call(wallet: wallet,
              payload: args['paymentDetails'],
              payment_method: args['paymentMethod'],
              amount: args['amount'])
    end
  end
end
