class CustomersController < ApplicationController
  skip_before_action :verify_authenticity_token,
                     only: :upload_customer_attachment
  def index
    @search = Customer.search(query_params)
    @customers = @search.result.page(params[:page])
  end

  def show
    @customer = Customer.find(params[:id])
    @labels = Label.all
  end

  def account_management
    @customer = Customer.find(params[:id])
    @entry_request = EntryRequest.new(customer: @customer)
    @entry_requests = @customer.entry_requests.page(params[:page])
  end

  def activity
    @customer = Customer.find(params[:id])
    @entries = @customer.entries.page(params[:page])
    @audit_logs = AuditLog
                  .where(origin_kind: :customer,
                         origin_id: @customer.id)
                  .page(params[:page])
  end

  def notes
    @customer = Customer.find(params[:id])
    @note = CustomerNote.new(customer: @customer)
    @customer_notes = @customer.customer_notes.page(params[:page]).per(5)
  end

  def update_labels
    customer = Customer.find(params[:id])
    if labels_params[:ids].include? '0'
      customer.labels.clear
    else
      customer.label_ids = labels_params[:ids]
    end
  end

  def upload_customer_attachment
    customer = Customer.find(params[:id])
    return false unless customer.valid?
    customer.customer_attachment.attach(
      customer_attachment_upload_params[:customer_attachment]
    )
  end

  private

  def labels_params
    params.require(:labels).permit(ids: [])
  end

  def customer_attachment_upload_params
    params.require(:customer).permit(:id, :customer_attachment)
  end
end
