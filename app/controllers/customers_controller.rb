# rubocop:disable Metrics/ClassLength
class CustomersController < ApplicationController
  include Labelable
  include DateIntervalFilters

  before_action :customer, only: %i[bonuses documents deposit_limit show]

  def index
    @search = Customer.search(query_params)
    @customers = @search.result.page(params[:page])
  end

  def show
    @labels = Label.where(kind: :customer)
  end

  def impersonate
    frontend_url = Customers::ImpersonationService.call(current_user, customer)
    current_user.log_event(:impersonate_customer, {}, customer)

    redirect_to frontend_url
  end

  def account_management
    @entry_request = EntryRequest.new(customer: customer)
    @entry_requests = customer.entry_requests.page(params[:page])
  end

  def activity
    @search = customer.entries.search(query_params)
    @entries = @search.result.page(params[:page])
    @audit_logs = AuditLog
                  .where(customer_id: customer.id)
                  .page(params[:page])
  end

  def bonuses
    @bonuses = Bonus.all
    @history =
      ActivatedBonus.customer_history(customer)
    return if customer.activated_bonus && !customer.activated_bonus.expired?

    @primary_wallet = customer.wallet_with_primary_currency
    @new_bonus = ActivatedBonus.new(
      customer: customer,
      wallet: @primary_wallet
    )
  end

  def notes
    @note = CustomerNote.new(customer: customer)
    @customer_notes = customer.customer_notes.page(params[:page]).per(5)
  end

  def documents
  end

  def betting_limits
    @global_limit = BettingLimit
                    .find_or_initialize_by(
                      customer: customer,
                      title: nil
                    )
    @limits_by_sports = BettingLimitFacade
                        .new(customer)
                        .for_customer
  end

  def deposit_limit
  end

  def bets
    query = prepare_interval_filter(query_params, :created_at)
    @filter = BetsFilter.new(bets_source: customer.bets,
                             query: query,
                             page: params[:page])
  end

  def documents_history
    @document_type = document_type
    type_included = VerificationDocument::KINDS.include?(
      @document_type.to_sym
    )
    raise ArgumentError, 'Document type not supported' unless type_included

    @files = customer.verification_documents.with_deleted.send(@document_type)
  end

  def upload_documents
    flash[:file_errors] = {}
    documents_from_params.each do |kind, file|
      document = customer.verification_documents.build(kind: kind,
                                                       status: :pending)
      document.document.attach(file)
      unless document.save
        flash[:file_errors][kind] = document.errors.full_messages.first
      end
    end
    redirect_to documents_customer_path(customer)
  end

  def update_status
    customer.update!(status_params)
    redirect_to documents_customer_path(customer)
  end

  def reset_password_to_default
    new_password = SecureRandom.base64(16)
    customer.update!(password: new_password)
    current_user.log_event :password_reset_to_default,
                           nil,
                           customer
    render json: { password: new_password }
  end

  def update_personal_information
    customer.update!(personal_information_params)
    flash[:success] = t(:updated, instance: t('entities.personal_information'))
    current_user.log_event :customer_personal_information_updated,
                           nil,
                           customer
    redirect_to customer_path(customer)
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.message
    redirect_to customer_path(customer)
  end

  def update_contact_information
    customer.update!(contact_information_params)
    flash[:success] = t(:updated, instance: t('entities.contact_information'))
    current_user.log_event :customer_contact_information_updated,
                           nil,
                           customer
    redirect_to customer_path(customer)
  rescue ActiveRecord::RecordInvalid => e
    flash[:error] = e.message
    redirect_to customer_path(customer)
  end

  def update_lock
    customer.update!(lock_params)
    current_user.log_event locking_event,
                           CustomerLocking.new(customer).to_h,
                           customer

    redirect_to customer_path(customer),
                success: t('messages.customer_lock_status_changed')
  end

  def account_update
    customer.update!(account_params)
    set_labelable_resource
    update_label_ids

    redirect_to customer_path(customer)
  end

  private

  def account_params
    params.require(:customer).permit(:agreed_with_promotional, :account_kind)
  end

  def status_params
    params.require(:customer).permit(:verified)
  end

  def personal_information_params
    params
      .require(:customer)
      .permit(
        :first_name,
        :last_name,
        :gender,
        :date_of_birth
      )
  end

  def contact_information_params
    params
      .require(:customer)
      .permit(
        :email,
        :phone,
        address_attributes: %i[country street_address zip_code city state]
      )
  end

  def lock_params
    params.require(:customer).permit(:locked, :lock_reason, :locked_until)
  end

  def customer
    @customer ||= Customer.find(params[:id])
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

  def locking_event
    @customer.locked ? :customer_locked : :customer_unlocked
  end
end
# rubocop:enable Metrics/ClassLength
