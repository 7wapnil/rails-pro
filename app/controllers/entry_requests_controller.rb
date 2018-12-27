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
    entry_request = EntryRequest.new(payload_params)

    if entry_request.save
      EntryRequestProcessingWorker.perform_async(entry_request.id)
      customer = entry_request.customer
      current_user.log_event :entry_request_created,
                             entry_request,
                             customer
      flash[:success] = t('messages.entry_request.flash')
      redirect_to account_management_customer_path(customer)
    else
      flash[:error] = entry_request.errors.full_messages
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
end
