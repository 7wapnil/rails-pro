class User < ApplicationRecord
  include Person
  include LoginAttemptable

  devise :database_authenticatable, :recoverable,
         :rememberable, :trackable, :validatable,
         authentication_keys: %i[email]

  has_many :entry_requests, as: :initiator

  def log_event(event, context = {}, customer = nil)
    Audit::Service.call(event: event,
                        user: self,
                        customer: customer,
                        context: context)
  end
end
