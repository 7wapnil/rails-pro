# rubocop:disable Metrics/ClassLength
class CustomersController < ApplicationController
  include Labelable
  include DateIntervalFilters

  NOTES_PER_PAGE = 5
  WIDGET_NOTES_COUNT = 2

  before_action :customer, only: %i[
    bonuses
    documents
    deposit_limit
    show
    create_fake_deposit
  ]
  before_action :new_note, only: %i[
    account_management
    activity
    betting_limits
    bonuses
    documents
    deposit_limit
    notes
    show
  ]
  before_action :customer_notes_widget, only: %i[
    account_management
    activity
    betting_limits
    bonuses
    documents
    deposit_limit
    show
  ]

  def index
    @search = Customer.ransack(query_params)
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
    @search = customer.entries.ransack(query_params)
    @entries = @search.result.page(params[:page])
    @audit_logs = AuditLog
                  .where(customer_id: customer.id)
                  .page(params[:page])
  end

  def create_fake_deposit
    deposit = deposit_params
    payment_provider = PaymentProvider::FakeDeposit.new
    fake_credit = {}
    amount = deposit[:amount].to_f
    if payment_provider.pay!(amount, fake_credit)
      wallet = customer.wallets.where(currency_id: deposit[:currency_id]).first
      Deposits::PlacementService.call(wallet, amount)
      flash[:notice] = I18n.t('events.deposit_created')
    else
      flash[:alert] = I18n.t('events.deposit_failed')
    end
    redirect_back fallback_location: account_management_customer_path(customer)
  end

  def bonuses
    @history =
      CustomerBonus.customer_history(customer)
    return if customer.customer_bonus && !customer.customer_bonus.expired?

    @active_bonuses = Bonus.active
    @default_wallet = customer.wallets.primary.take
    @new_bonus = CustomerBonus.new(
      customer: customer,
      wallet: @default_wallet
    )
  end

  def notes
    @customer_notes =
      customer.customer_notes.page(params[:page]).per(NOTES_PER_PAGE)
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
    current_user.log_event(
      customer.verified ? :customer_verified : :customer_verification_revoked,
      nil,
      customer
    )
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
    flash[:success] = t(
      :updated,
      instance: t('attributes.personal_information')
    )
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
    flash[:success] = t(
      :updated,
      instance: t('attributes.contact_information')
    )
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
                success: t(:updated, instance: t('attributes.lock_status'))
  end

  def account_update
    agreed = account_params[:agreed_with_promotional] == 'on'
    agreement_changed = customer.agreed_with_promotional != agreed
    customer.update!(account_params)
    set_labelable_resource
    update_label_ids
    if agreement_changed
      current_user.log_event(
        agreed ? :promotional_accepted : :promotional_revoked,
        nil,
        customer
      )
    end
    redirect_to customer_path(customer)
  end

  private

  def deposit_params
    params.require(:deposit).permit(:currency_id, :amount)
  end

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

  def new_note
    @note = CustomerNote.new(customer: customer)
  end

  def customer_notes_widget
    @customer_notes_widget = customer.customer_notes.limit(WIDGET_NOTES_COUNT)
  end
end
# rubocop:enable Metrics/ClassLength
