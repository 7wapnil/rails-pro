module ApplicationCable
  class Connection < ActionCable::Connection::Base
    include Authentication

    authenticatable source: :query,
                    key: :token
    identified_by :customer, :impersonated_by

    def connect
      self.customer = current_customer
      self.impersonated_by = impersonated_by
    end
  end
end
