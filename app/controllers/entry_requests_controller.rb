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
    form = EntryRequestForm.new(payload_params)
    entry_request = form.submit

    if entry_request
      current_user.log_event :entry_request_created, entry_request, customer
      flash[:success] = t('messages.entry_request.flash')
      redirect_to account_management_customer_path(customer)
    else
      flash[:error] = form.errors
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
