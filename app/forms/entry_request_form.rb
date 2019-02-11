# frozen_string_literal: true

class EntryRequestForm
  attr_reader :errors, :params
  def initialize(entry_request_params)
    @params = entry_request_params
    @amount = params[:amount].to_f
    @errors = []
  end

  def submit
    return create_and_proceed_deposit if deposit_simulation?

    create_entry_request
  end

  private

  attr_reader :amount, :deposit

  def deposit_simulation?
    params[:kind] == EntryRequest::DEPOSIT &&
      params[:mode] == EntryRequest::SIMULATED
  end

  def create_entry_request
    entry_request = EntryRequest.new(params)
    @errors = entry_request.errors.full_messages unless entry_request.save
    return unless errors.empty?

    EntryRequestProcessingWorker.perform_async(entry_request.id)
    entry_request
  end

  def create_and_proceed_deposit
    create_deposit!
    raise if deposit.failed?

    ::EntryRequests::DepositWorker.perform_async(deposit.id)

    deposit
  rescue StandardError
    errors.push I18n.t('events.deposit_failed')
    nil
  end

  def create_deposit!
    @deposit = EntryRequests::Factories::Deposit.call(
      wallet: wallet,
      amount: amount,
      **deposit_payload
    )
  end

  def deposit_payload
    params.slice(:comment, :mode, :initiator).to_h.symbolize_keys
  end

  def wallet
    Wallet.find_or_create_by!(
      customer_id: params[:customer_id],
      currency_id: params[:currency_id]
    )
  end
end
