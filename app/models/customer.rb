class Customer < ApplicationRecord # rubocop:disable Metrics/ClassLength:
  include Person

  after_validation :check_account_transition_rule
  has_secure_token :activation_token
  acts_as_paranoid

  enum gender: {
    male: 0,
    female: 1
  }

  enum account_kind: {
    regular: 0,
    staff: 1,
    test: 2
  }

  enum lock_reason: {
    self_exclusion: 0,
    cooling_off: 1,
    locked: 2,
    closed: 3,
    password_recovery: 4,
    fraud: 5
  }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable,
         authentication_keys: [:login]

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

  has_many :customer_notes
  has_many :wallets
  has_many :entries, through: :wallets
  has_many :entry_requests
  has_many :initiated_entry_requests, as: :initiator, class_name: 'EntryRequest'
  has_one :address
  has_many :label_joins, as: :labelable
  has_many :labels, through: :label_joins
  has_many :verification_documents
  has_many :betting_limits
  has_many :bets

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

  validates :username,
            :email,
            :first_name,
            :last_name,
            :date_of_birth,
            :password,
            presence: true

  validates :password, confirmation: true
  validates :password, length: { minimum: 6, maximum: 32 }

  validates :email, format: /\A[\w\d_\-\.]+@[\w\d_\-\.]+\z/

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

  def check_account_transition_rule
    return if !account_kind_changed? || account_kind_was.nil?

    msg = "can't transit customer account kind"
    raise msg unless account_kind_was == 'regular'
  end
end
