class CustomersController < ApplicationController
  def index
    @search = Customer.search(query_params)
    @customers = @search.result.page(params[:page])
  end

  def show
    @customer = find_customer_by_id
    @labels = Label.all
  end

  def account_management
    @customer = find_customer_by_id
    @entry_request = EntryRequest.new(customer: @customer)
    @entry_requests = @customer.entry_requests.page(params[:page])
  end

  def activity
    @customer = find_customer_by_id
    @entries = @customer.entries.page(params[:page])
    @audit_logs = AuditLog
                  .where(origin_kind: :customer,
                         origin_id: @customer.id)
                  .page(params[:page])
  end

  def notes
    @customer = find_customer_by_id
    @note = CustomerNote.new(customer: @customer)
    @customer_notes = @customer.customer_notes.page(params[:page]).per(5)
  end

  def documents
    @customer = find_customer_by_id
  end

  def upload_documents
    @customer = find_customer_by_id
    documents_from_params.each do |attachment_type, file|
      plural_attachment_type = attachment_type.pluralize
      @customer.send(plural_attachment_type).attach(file)
    end
    redirect_to documents_customer_path(@customer)
  end

  def update_labels
    customer = find_customer_by_id
    if labels_params[:ids].include? '0'
      customer.labels.clear
    else
      customer.label_ids = labels_params[:ids]
    end
  end

  private

  def labels_params
    params.require(:labels).permit(ids: [])
  end

  def find_customer_by_id
    Customer.find(params[:id])
  end

  def documents_from_params
    params
      .permit(*Customer::ATTACHMENT_TYPES)
  end
end
