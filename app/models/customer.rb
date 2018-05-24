class Customer < ApplicationRecord
  enum gender: {
    male: 0,
    female: 1
  }

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         authentication_keys: [:username]

  has_one :address

  # Devise Validatable module creates all needed
  # validations for a user email and password.

  validates :username,
            :first_name,
            :last_name,
            :date_of_birth,
            presence: true

  validates :username, uniqueness: { case_sensitive: false }
end
