class Customer < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :address

  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
end
