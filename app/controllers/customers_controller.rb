class CustomersController < ApplicationController
  include Labelable

  def index
    @search = Customer.search(query_params)
    @customers = @search.result.page(params[:page])
  end

  def show
    @customer = find_customer
    @labels = Label.where(kind: :customer)
  end

  def account_management
    @customer = find_customer
    @entry_request = EntryRequest.new(customer: @customer)
    @entry_requests = @customer.entry_requests.page(params[:page])
  end

  def activity
    @customer = find_customer
    @search = @customer.entries.search(query_params)
    @entries = @search.result.page(params[:page])
    @audit_logs = AuditLog
                  .where(customer_id: @customer.id)
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
    @document_type = document_type
    type_included = VerificationDocument::KINDS.include?(
      @document_type.to_sym
    )
    raise ArgumentError, 'Document type not supported' unless type_included

    @files = @customer.verification_documents.with_deleted.send(@document_type)
  end

  def upload_documents
    @customer = find_customer
    flash[:file_errors] = {}
    documents_from_params.each do |kind, file|
      document = @customer.verification_documents.build(kind: kind,
                                                        status: :pending)
      document.document.attach(file)
      unless document.save
        flash[:file_errors][kind] = document.errors.full_messages.first
      end
    end
    redirect_to documents_customer_path(@customer)
  end

  def update_promotional_subscription
    @customer = find_customer
    agreed = customer_params[:agreed_with_promotional]
    updated = @customer.update_column(:agreed_with_promotional, agreed)
    status = updated ? :ok : :unprocessable_entity
    message = updated ? 'Updated!' : @customer.errors.full_messages.first

    render json: { message: message }, status: status
  end

  def update_customer_status
    @customer = find_customer

    @customer.update(verified: customer_verification_status == 'true')
    redirect_to documents_customer_path(@customer)
  end

  private

  def customer_params
    params.require(:customer).permit(:agreed_with_promotional)
  end

  def find_customer
    Customer.find(params[:id])
  end

  def documents_from_params
    params
      .permit(*VerificationDocument::KINDS)
  end

  def document_type
    params.require(:document_type)
  end

  def customer_verification_status
    params.require(:verified)
  end
end
