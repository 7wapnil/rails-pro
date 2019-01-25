class EntryRequestsController < ApplicationController
  def index
    @filter = EntryRequestsFilter.new(
      source: EntryRequest,
      query_params: query_params(:entry_requests),
      page: params[:page]
    )
  end

  def show
    @request = EntryRequest.find(params[:id])
  end

  def create
    customer = Customer.find(payload_params[:customer_id])
    @entry_request = if deposit_simulation?
                       handle_deposit_simulation(customer)
                     else
                       handle_entry_request_creation
                     end

    if @entry_request
      current_user.log_event :entry_request_created, @entry_request, customer

      redirect_to account_management_customer_path(customer)
    else
      redirect_back fallback_location: root_path
    end
  end

  private

  def payload_params
    params
      .require(:entry_request)
      .permit(:customer_id, :currency_id, :amount, :kind, :mode, :comment)
      .merge(initiator: current_user)
  end

  def deposit_simulation?
    payload_params[:kind] == EntryRequest::DEPOSIT &&
      payload_params[:mode] == EntryRequest::SIMULATED
  end

  def handle_entry_request_creation
    entry_request = EntryRequest.new(payload_params)

    if entry_request.save
      EntryRequestProcessingWorker.perform_async(entry_request.id)
      flash[:success] = t('messages.entry_request.flash')
      entry_request
    else
      flash[:error] = entry_request.errors.full_messages
      nil
    end
  end

  def handle_deposit_simulation(customer)
    amount = payload_params[:amount].to_f
    wallet = Wallet.find_or_create_by!(
      customer: customer,
      currency_id: payload_params[:currency_id]
    )
    payload = payload_params.slice(:comment, :mode, :initiator)
                            .to_h
                            .symbolize_keys

    entry_request = Deposits::PlacementService.call(wallet, amount, **payload)
    flash[:success] = I18n.t('events.deposit_created') if entry_request
    flash[:error] = I18n.t('events.deposit_failed') unless entry_request
    entry_request
  end
end
