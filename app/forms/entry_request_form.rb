class EntryRequestForm
  attr_reader :errors, :params
  def initialize(entry_request_params)
    @params = entry_request_params
    @errors = []
  end

  def submit
    deposit_simulation? ? create_deposit : create_entry_request
  end

  private

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

  def create_deposit
    amount = params[:amount].to_f
    wallet = Wallet.find_or_create_by!(
      customer_id: params[:customer_id],
      currency_id: params[:currency_id]
    )
    payload = params.slice(:comment, :mode, :initiator)
                    .to_h
                    .symbolize_keys

    entry_request = Deposits::PlacementService.call(wallet, amount, **payload)
    errors.push I18n.t('events.deposit_failed') unless entry_request
    entry_request
  end
end
