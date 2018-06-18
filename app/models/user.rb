class User < ApplicationRecord
  include Person

  devise :database_authenticatable, :recoverable, :rememberable,
         :trackable, :validatable,
         authentication_keys: [:email]

  has_many :entry_requests, as: :origin
end
