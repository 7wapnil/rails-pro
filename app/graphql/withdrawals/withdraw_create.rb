module Withdrawals
  class WithdrawCreate < ::Base::Resolver
    type WithdrawalResultType

    description 'Create withdrawal'

    argument :amount, !types.Float
    argument :walletId, !types.ID
    argument :payment_method, types.String

    def resolve(_obj, args)
      wallet = find_customer_wallet(args['walletId'])
      request = Withdrawals::WithdrawalService.call(wallet,
                                                    args['amount'],
                                                    EntryRequest::CASHIER)
      OpenStruct.new(
        entryRequest: request,
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
  end
end
