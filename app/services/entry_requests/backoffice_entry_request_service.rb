module EntryRequests
  class BackofficeEntryRequestService < ApplicationService
    def initialize(entry_request_params)
      @params = entry_request_params
      @amount = params[:amount].to_f
    end

    def call
      deposit? ? create_and_proceed_deposit : create_and_proceed_withdrawal
      entry_request_error! if entry_request.failed?

      entry_request
    end

    private

    attr_reader :entry_request, :params, :amount, :technical_errors

    def deposit?
      params[:kind] == EntryRequest::DEPOSIT
    end

    def create_and_proceed_withdrawal
      create_withdrawal_entry_request
      return if entry_request.failed?

      process_withdraw_entry_request
      entry_request.withdrawal.succeeded!
    end

    def create_and_proceed_deposit
      create_deposit_entry_request
      return if entry_request.failed?

      process_deposit_entry_request
      entry_request.deposit.succeeded!
    end

    def process_deposit_entry_request
      ::EntryRequests::DepositWorker.perform_async(entry_request.id)
    end

    def process_withdraw_entry_request
      ::EntryRequestProcessingWorker.perform_async(entry_request.id)
    end

    def create_deposit_entry_request
      @entry_request = EntryRequests::Factories::Deposit.call(
        transaction: deposit_transaction
      )
    end

    def create_withdrawal_entry_request
      @entry_request = EntryRequests::Factories::Withdrawal.call(
        transaction: withdrawal_transaction
      )
    end

    def deposit_transaction
      ::Payments::Transactions::Deposit.new(
        method: params[:mode],
        customer: Customer.find_by(id: params[:customer_id]),
        amount: amount,
        comment: params[:comment],
        initiator: params[:initiator],
        currency_code: Currency.find_by(id: params[:currency_id])&.code
      )
    end

    def withdrawal_transaction
      ::Payments::Transactions::Withdrawal.new(
        method: params[:mode],
        customer: Customer.find_by(id: params[:customer_id]),
        amount: amount,
        comment: params[:comment],
        initiator: params[:initiator],
        currency_code: Currency.find_by(id: params[:currency_id])&.code
      )
    end

    def entry_request_error!
      raise EntryRequests::ValidationError, entry_request.result['message']
    end
  end
end
