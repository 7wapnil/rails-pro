class User < ApplicationRecord
  include Person

  LOGIN_ATTEMPTS_SOFT_CAP = 3

  devise :database_authenticatable, :recoverable, :rememberable,
         :trackable, :validatable, :lockable,
         authentication_keys: %i[email]

  has_many :entry_requests, as: :initiator

  def brute_forced?
    failed_attempts >= LOGIN_ATTEMPTS_SOFT_CAP
  end

  def log_event(event, context = {}, customer = nil)
    Audit::Service.call(event: event,
                        user: self,
                        customer: customer,
                        context: context)
  end
end
