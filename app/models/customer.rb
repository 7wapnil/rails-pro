class Customer < ApplicationRecord
  include Person

  ATTACHMENT_TYPES = %i[
    personal_ids
    utility_bills
    bank_statements
    credit_cards
    other_documents
  ].freeze

  MAX_ATTACHMENT_SIZE = 2.megabytes.freeze

  acts_as_paranoid

  enum gender: {
    male: 0,
    female: 1
  }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
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
  has_and_belongs_to_many :labels

  ATTACHMENT_TYPES.each do |attachment_type|
    has_many_attached attachment_type
  end

  ATTACHMENT_TYPES.each do |attachment_type|
    validates attachment_type,
              file_size: { less_than_or_equal_to: MAX_ATTACHMENT_SIZE },
              file_content_type: { allow: %w[image/jpeg
                                             image/png
                                             image/jpg
                                             application/pdf] },
              if: proc { |customer|
                customer.send(attachment_type).attached?
              }
  end

  # Devise Validatable module creates all needed
  # validations for a user email and password.

  validates :username,
            :email,
            :first_name,
            :last_name,
            :date_of_birth,
            presence: true

  validates :username, uniqueness: { case_sensitive: false }
  validates :email, uniqueness: { case_sensitive: false }

  ransack_alias :ip_address, :last_sign_in_ip_or_current_sign_in_ip
end
