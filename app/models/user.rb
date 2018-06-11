class User < ApplicationRecord
  include Person

  devise :database_authenticatable, :recoverable, :rememberable,
         :trackable, :validatable,
         authentication_keys: [:email]

  def full_name
    [first_name, last_name].join(' ')
  end
end
