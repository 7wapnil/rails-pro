module Withdrawals
  class Create < ::Base::Resolver
    type WithdrawalResultType

    description 'Create withdrawal'

    argument :amount, !types.Float
    argument :walletId, !types.ID
    argument :payment_method, types.String

    def resolve(_obj, args)
      wallet = find_customer_wallet(args['walletId'])
      withdrawal = create_withdrawal!(wallet, args['amount'])
      EntryRequests::WithdrawalWorker.perform_async(withdrawal.id)

      OpenStruct.new(
        entryRequest: withdrawal,
        error: nil
      )
    rescue StandardError => e
      OpenStruct.new(
        entryRequest: nil,
        error: e.message
      )
    end

    private

    def find_customer_wallet(wallet_id)
      @current_customer.wallets.find(wallet_id)
    end

    def create_withdrawal!(wallet, amount)
      EntryRequests::Factories::Withdrawal.call(wallet: wallet, amount: amount)
    end
  end
end
