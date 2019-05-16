# frozen_string_literal: true

class Customer < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Person
  include LoginAttemptable

  after_update :log_account_transition

  has_secure_token :activation_token
  has_secure_token :email_verification_token
  acts_as_paranoid

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
  has_many :labels, through: :label_joins
  has_many :verification_documents
  has_many :betting_limits
  has_many :bets
  has_many :statistics,
           class_name: Customers::Statistic.name,
           inverse_of: :customer

  has_one :address, autosave: true, dependent: :destroy
  has_many :customer_bonuses, dependent: :destroy

  delegate :street_address,
           :zip_code,
           :country,
           :state,
           :city,
           to: :address, allow_nil: true, prefix: true

  accepts_nested_attributes_for :address
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
            :first_name,
            :last_name,
            :date_of_birth,
            presence: true

  validates :username, uniqueness: { case_sensitive: false }
  validates :email, uniqueness: { case_sensitive: false }
  validates :verified, :activated, :locked, inclusion: { in: [true, false] }
  validates :phone, phone: true
  validates_with AgeValidator
  ransack_alias :ip_address, :last_sign_in_ip_or_current_sign_in_ip

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

  def log_event(event, context = {})
    Audit::Service.call(event: event,
                        user: nil,
                        customer: self,
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

  def active_bonus
    customer_bonuses.active.first
  end

  def pending_bonus
    customer_bonuses.initial.last
  end

  def deposit_attempts
    entry_requests
      .deposit
      .where.not(status: EntryRequest::SUCCEEDED)
      .where('created_at >= ?', 24.hours.ago)
      .count
  end

  def available_withdraw_methods
    entry_requests
      .deposit
      .succeeded
      .order(created_at: :desc)
      .pluck(:mode)
      .uniq
  end

  private

  def log_account_transition
    ctx = {
      account_kind_was: account_kind_before_last_save,
      account_kind_become: account_kind
    }

    log_event(:account_kind_transition, ctx) if saved_change_to_account_kind?
  end

  def validate_account_transition
    return unless account_kind_changed?

    msg = I18n.t('errors.messages.account_transition',
                 from: account_kind_was,
                 to: account_kind)
    errors.add(:account_kind, msg) if account_kind_was != 'regular'
  end
end
