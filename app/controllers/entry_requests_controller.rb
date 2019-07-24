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
    entry_request = EntryRequests::BackofficeEntryRequestService
                    .call(payload_params)

    current_user.log_event :entry_request_created, entry_request, customer
    flash[:success] = t('messages.entry_request.flash')
    redirect_to account_management_customer_path(customer)
  rescue Wallets::ValidationError, EntryRequests::ValidationError => error
    flash[:error] = error.message
    redirect_back fallback_location: root_path
  end

  private

  def payload_params
    params
      .require(:entry_request)
      .permit(:customer_id, :currency_id, :amount, :kind, :mode, :comment)
      .merge(initiator: current_user)
  end
end
