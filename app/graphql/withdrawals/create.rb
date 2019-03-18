module Withdrawals
  class Create < ::Base::Resolver
    type WithdrawalResultType

    description 'Create withdrawal'

    argument :amount, !types.Float
    argument :walletId, !types.ID
    argument :payment_method, !types.String
    argument :payment_details, types[PaymentDetail]

    def resolve(_obj, args)
      wallet = find_customer_wallet(args['walletId'])
      withdrawal = create_withdrawal!(wallet, args['amount'])
      create_withdrawal_request!(withdrawal, args) if withdrawal
      EntryRequests::WithdrawalWorker.perform_async(withdrawal.id)

      OpenStruct.new(
        **withdrawal.attributes.symbolize_keys,
        success: true,
        error_messages: nil
      )
    rescue StandardError => error
      respond_with_error(error)
    end

    private

    def respond_with_error(error)
      errors = if error.instance_of? ActiveRecord::RecordInvalid
                 error.record.errors.full_messages
               else
                 [error.message]
               end

      OpenStruct.new(success: false, error_messages: errors)
    end

    def find_customer_wallet(wallet_id)
      @current_customer.wallets.find(wallet_id)
    end

    def create_withdrawal!(wallet, amount)
      EntryRequests::Factories::Withdrawal.call(wallet: wallet, amount: amount)
    end

    def create_withdrawal_request!(entry_request, args)
      WithdrawalRequests::Create.call(entry_request: entry_request,
                                      payload: args['payment_details'],
                                      payment_method: args['payment_method'])
    end
  end
end
