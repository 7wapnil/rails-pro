class Customer < ApplicationRecord
  include Person

  acts_as_paranoid

  enum gender: {
    male: 0,
    female: 1
  }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         authentication_keys: [:username]

  has_many :customer_notes
  has_many :wallets
  has_many :entries, through: :wallets
  has_many :entry_requests
  has_many :initiated_entry_requests, as: :initiator, class_name: 'EntryRequest'

  has_one :address
  has_and_belongs_to_many :labels

  # Devise Validatable module creates all needed
  # validations for a user email and password.

  validates :username,
            :first_name,
            :last_name,
            :date_of_birth,
            presence: true

  validates :username, uniqueness: { case_sensitive: false }

  ransack_alias :ip_address, :last_sign_in_ip_or_current_sign_in_ip
end
