# frozen_string_literal: true

class EntryRequestForm
  attr_reader :errors, :params

  def initialize(entry_request_params)
    @params = entry_request_params
    @amount = params[:amount].to_f
    @errors = []
  end

  def submit
    return create_and_proceed_deposit if deposit?

    create_and_proceed_withdrawal
  end

  private

  attr_reader :amount, :deposit

  def deposit?
    params[:kind] == EntryRequest::DEPOSIT
  end

  # TODO: refactor using factories and services for withdrawal
  def create_and_proceed_withdrawal
    find_or_create_wallet!
    entry_request = EntryRequest.new(params)
    @errors = entry_request.errors.full_messages unless entry_request.save
    return unless errors.empty?

    EntryRequestProcessingWorker.perform_async(entry_request.id)
    entry_request
  rescue Wallets::ValidationError => error
    errors.push(error.message)
    nil
  end

  def create_and_proceed_deposit
    create_deposit!
    return deposit_error! if deposit.failed?

    ::EntryRequests::DepositWorker.perform_async(deposit.id)
    deposit
  rescue FormInvalidError, Wallets::ValidationError => error
    errors.push(error.message)
    nil
  end

  def create_deposit!
    @deposit = EntryRequests::Factories::Deposit.call(
      wallet: find_or_create_wallet!,
      amount: amount,
      **deposit_payload
    )
  end

  def deposit_error!
    raise FormInvalidError, deposit.result['message']
  end

  def deposit_payload
    params.slice(:comment, :mode, :initiator).to_h.symbolize_keys
  end

  def find_or_create_wallet!
    Wallets::FindOrCreate.call(
      customer_id: params[:customer_id],
      currency_id: params[:currency_id]
    )
  end
end
