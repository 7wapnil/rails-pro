# rubocop:disable Metrics/ClassLength
class CustomersController < ApplicationController
  include Labelable
  include DateIntervalFilters

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

  def betting_limits
    @customer = find_customer
    @customer_limits = BettingLimitFacade
                       .new(@customer)
                       .for_customer
  end

  def bets
    @customer = find_customer
    query = prepare_interval_filter(query_params, :created_at)
    @filter = BetsFilter.new(bets_source: @customer.bets,
                             query: query,
                             page: params[:page])
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
    @customer.update_column(:agreed_with_promotional, agreed)
    message = I18n.t('attribute_updated', attribute: 'Promotional agreement')

    render json: { message: message }
  end

  def update_customer_status
    @customer = find_customer

    @customer.update_column(:verified, customer_verification_status == 'true')
    redirect_to documents_customer_path(@customer)
  end

  def reset_password_to_default
    @customer = find_customer
    o = [
      ('a'..'z'),
      ('A'..'Z'),
      ('0'..'9'),
      %w[! @ # $ % ? : { }]
    ].flat_map(&:to_a)
    new_password = (0...16).map { o[rand(o.length)] }.join
    @customer.update(password: new_password)
    render json: { password: new_password }
  end

  def update_personal_information
    @customer = find_customer
    puts params[:customer][:date_of_birth]
    @customer.update_columns(
      first_name: params[:customer][:first_name],
      last_name: params[:customer][:last_name],
      gender: params[:customer][:gender],
      date_of_birth: params[:customer][:date_of_birth]
    )
    current_user.log_event :customer_personal_information_updated,
                           nil,
                           @customer
    redirect_to customer_path(@customer)
  end

  def update_contact_information
    @customer = find_customer
    @customer.update_columns(
      email: params[:customer][:email],
      phone: params[:customer][:phone]
    )
    update_customer_address!
    current_user.log_event :customer_contact_information_updated,
                           nil,
                           @customer
    redirect_to customer_path(@customer)
  end

  def update_lock
    @customer = find_customer
    @customer.update_columns(
      locked: params[:locked] == 'true',
      lock_reason: params[:lock_reason] != '' ? params[:lock_reason] : nil,
      locked_until: params[:locked_until]
    )
    render json: {
      message: I18n.t('messages.customer_lock_status_changed')
    }
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

  def update_customer_address!
    @customer.address.update_columns(
      country: params[:customer][:address_country],
      street_address: params[:customer][:address_street_address],
      zip_code: params[:customer][:address_zip_code],
      city: params[:customer][:address_city],
      state: params[:customer][:address_state]
    )
  end
end
# rubocop:enable Metrics/ClassLength
