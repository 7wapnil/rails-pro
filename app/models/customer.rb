# frozen_string_literal: true

class Customer < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Person
  include LoginAttemptable

  after_update :log_account_transition
  after_commit :update_summary, on: :create

  has_secure_token :activation_token
  has_secure_token :email_verification_token
  acts_as_paranoid

  DEPOSIT_INFO_FIELDS = %w[first_name last_name phone].freeze
  ADDRESS_INFO_FIELDS = %w[country city street_address state zip_code].freeze

  enum gender: {
    male:   MALE   = 'male',
    female: FEMALE = 'female'
  }

  enum account_kind: {
    regular: REGULAR = 'regular',
    staff:   STAFF   = 'staff',
    testing: TESTING = 'testing'
  }

  enum lock_reason: {
    self_exclusion:    SELF_EXCLUSION    = 'self_exclusion',
    cooling_off:       COOLING_OFF       = 'cooling_off',
    locked:            LOCKED            = 'locked',
    closed:            CLOSED            = 'closed',
    password_recovery: PASSWORD_RECOVERY = 'password_recovery',
    fraud:             FRAUD             = 'fraud'
  }

  enum locale: I18n.available_locales.map { |code| [code, code.to_s] }.to_h

  devise :database_authenticatable, :registerable, :validatable,
         :recoverable, :rememberable, :trackable,
         authentication_keys: %i[login], password_length: 6..32

  attr_accessor :login

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      query = 'lower(username) = lower(:value) OR lower(email) = lower(:value)'
      where(conditions).where([query, { value: login.downcase }]).first
    else
      where(conditions).first
    end
  end

  has_many :deposit_limits
  has_many :customer_notes
  has_many :wallets
  has_many :currencies, through: :wallets
  has_many :entries, through: :wallets
  has_many :balance_entries, through: :wallets
  has_many :entry_requests
  has_many :initiated_entry_requests,
           as: :initiator,
           class_name: EntryRequest.name
  has_many :label_joins, as: :labelable
  has_many :labels,
           -> { where(system: false) },
           through: :label_joins
  has_many :system_labels,
           -> { where(system: true) },
           through: :label_joins,
           source: :label
  has_many :verification_documents
  has_many :betting_limits
  has_many :bets
  has_many :statistics,
           class_name: Customers::Statistic.name,
           inverse_of: :customer
  has_many :login_activities, as: :user

  has_one :address, autosave: true, dependent: :destroy
  has_many :customer_bonuses, dependent: :destroy
  has_one :active_bonus, -> { active }, class_name: CustomerBonus.name
  has_one :pending_bonus, -> { initial }, class_name: CustomerBonus.name

  accepts_nested_attributes_for :address, update_only: true

  has_one :wallet, -> { order(:created_at) }
  has_one :fiat_wallet,
          -> { joins(:currency).where(currencies: { kind: Currency::FIAT }) },
          class_name: Wallet.name

  has_one :customer_data

  has_many :every_matrix_transactions,
           class_name: EveryMatrix::Transaction.name,
           inverse_of: :customer

  delegate :street_address,
           :zip_code,
           :country,
           :state,
           :city,
           to: :address, allow_nil: true, prefix: true

  # Devise Validatable module creates all needed
  # validations for a user email and password.

  validate :validate_account_transition
  validates :username,
            :email,
            presence: true
  validates :date_of_birth,
            presence: { message: I18n.t('errors.messages.blank_birth_date') }

  validates :username, uniqueness: { case_sensitive: false }
  validates_format_of :username,
                      without: /\s/,
                      message: I18n.t('errors.messages.username_with_spaces')

  validates :email, uniqueness: { case_sensitive: false }
  validates :verified, :activated, :locked, inclusion: { in: [true, false] }

  validates :phone, phone: true, allow_blank: true

  validates_with AgeValidator
  ransack_alias :ip_address, :last_sign_in_ip_or_current_sign_in_ip
  ransacker :agg_labels do
    query = <<-SQL
      (SELECT STRING_AGG(
                '|' || label_joins.label_id::Text || '|', ','
              ) AS agg_labels
       FROM label_joins
       WHERE label_joins.labelable_id = customers.id AND
             label_joins.labelable_type = 'Customer'
       GROUP BY customers.id
       LIMIT 1
      )
    SQL
    Arel.sql(query)
  end

  VerificationDocument::KINDS.keys.each do |kind|
    define_method(kind) do
      verification_documents.where(kind: kind).last
    end
  end

  def documents_history(kind = nil)
    query = verification_documents
    query = query.where(kind: kind) if kind
    query.with_deleted
  end

  def log_event(event, context = {}, customer = self)
    Audit::Service.call(event: event,
                        user: nil,
                        customer: customer,
                        context: context)
  end

  def parsed_phone
    Phonelib.parse(phone)
  end

  def phone=(phone_number)
    normalized_phone = phone_number.gsub(/\D/, '')
    write_attribute(:phone, normalized_phone)
  end

  def locked?
    locked || (locked_until && Time.zone.now < locked_until)
  end

  def deposit_limit
    DepositLimit.find_or_initialize_by(customer: self)
  end

  def deposit_attempts
    entry_requests
      .deposit
      .where.not(status: EntryRequest::SUCCEEDED)
      .where('created_at >= ?', 24.hours.ago)
      .count
  end

  def available_withdrawal_methods
    ::Customers::AvailableWithdrawalMethods.call(customer: self)
  end

  def available_deposit_methods
    ::Customers::AvailableDepositMethods.call(customer: self)
  end

  def log_account_transition
    ctx = {
      account_kind_was: account_kind_before_last_save,
      account_kind_become: account_kind
    }

    log_event(:account_kind_transition, ctx) if saved_change_to_account_kind?
  end

  def update_summary
    Customers::Summaries::UpdateWorker
      .perform_async(Date.current, signups_count: 1)
  end

  def validate_account_transition
    return unless account_kind_changed?

    msg = I18n.t('internal.errors.messages.account_transition',
                 from: account_kind_was,
                 to: account_kind)
    errors.add(:account_kind, msg) if account_kind_was != 'regular'
  end
end
