# frozen_string_literal: true

module Payments
  class WithdrawalHandler < ::ApplicationService
    def initialize(transaction:)
      @transaction = transaction
    end

    def call
      form.validate!

      withdrawal_request = create_withdrawal_request!

      EntryRequests::WithdrawalWorker.perform_async(
        withdrawal_request.entry_request.id
      )
    end

    protected

    attr_reader :transaction

    private

    def form
      Forms::WithdrawRequest.new(
        amount: transaction.amount,
        password: transaction.password,
        wallet_id: transaction.wallet&.id,
        payment_method: transaction.method,
        payment_details: transaction.details,
        customer: transaction.customer
      )
    end

    def create_withdrawal_request!
      WithdrawalRequests::Create.call(
        wallet: transaction.wallet,
        payload: transaction.details,
        payment_method: transaction.method,
        amount: transaction.amount
      )
    end
  end
end
