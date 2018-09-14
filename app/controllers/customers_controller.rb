class CustomersController < ApplicationController
  def index
    @search = Customer.search(query_params)
    @customers = @search.result.page(params[:page])
  end

  def show
    @customer = find_customer
    @labels = Label.all
  end

  def account_management
    @customer = find_customer
    @entry_request = EntryRequest.new(customer: @customer)
    @entry_requests = @customer.entry_requests.page(params[:page])
  end

  def activity
    @customer = find_customer
    @entries = @customer.entries.page(params[:page])
    @audit_logs = AuditLog
                  .where(origin_kind: :customer,
                         origin_id: @customer.id)
                  .page(params[:page])
  end

  def notes
    @customer = find_customer
    @note = CustomerNote.new(customer: @customer)
    @customer_notes = @customer.customer_notes.page(params[:page]).per(5)
  end

  def documents
    @customer = find_customer
  end

  def documents_history
    @customer = find_customer
    type_included = Customer::ATTACHMENT_TYPES.include?(
      params[:document_type].to_sym
    )
    raise ArgumentError unless type_included
    @files = @customer.public_send(params[:document_type])
  end

  def upload_documents
    @customer = find_customer
    documents_from_params.each do |attachment_type, file|
      @customer.send(attachment_type).attach(file)
    end
    redirect_to documents_customer_path(@customer)
  end

  def update_labels
    customer = find_customer
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

  def find_customer
    Customer.find(params[:id])
  end

  def documents_from_params
    params
      .permit(*Customer::ATTACHMENT_TYPES)
  end
end
