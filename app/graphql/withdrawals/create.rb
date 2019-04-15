module Withdrawals
  class Create < ::Base::Resolver
    type !types.Boolean
    description 'Create withdrawal request'

    argument :input, Inputs::WithdrawInput

    def resolve(_obj, args)
      input = args['input']
      withdrawal_data = input.to_h
      withdrawal_data[:customer_verified] = current_customer.verified
      Forms::WithdrawRequest.new(withdrawal_data).validate!

      validate_password!(input['password'])
      withdrawal_request = create_withdrawal_request!(input)
      EntryRequests::WithdrawalWorker
        .perform_async(withdrawal_request.entry_request.id)

      true
    end

    private

    def validate_password!(password)
      return if current_customer.valid_password?(password)

      raise ResolvingError, password: I18n.t('errors.messages.password_invalid')
    end

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
