module Withdrawals
  class Create < ::Base::Resolver
    type WithdrawalResultType

    description 'Create withdrawal'

    argument :amount, !types.Float
    argument :walletId, !types.ID
    argument :payment_method, !types.String
    argument :payment_details, types[PaymentMethodDetail]

    def resolve(_obj, args)
      withdrawal_request = create_withdrawal_request!(args)
      EntryRequests::WithdrawalWorker
        .perform_async(withdrawal_request.entry_request.id)

      OpenStruct.new(
        **withdrawal_request.entry_request.attributes.symbolize_keys,
        success: true,
        error_messages: nil
      )
    rescue StandardError => error
      respond_with_error(error)
    end

    private

    delegate :wallets, to: :current_customer, prefix: :customer

    def respond_with_error(error)
      errors = if error.instance_of? ActiveRecord::RecordInvalid
                 error.record.errors.full_messages
               else
                 [error.message]
               end

      OpenStruct.new(success: false, error_messages: errors)
    end

    def create_withdrawal_request!(args)
      WithdrawalRequests::Create
        .call(wallet: customer_wallets.find(args['walletId']),
              payload: args['payment_details'],
              payment_method: args['payment_method'],
              amount: args['amount'])
    end
  end
end
