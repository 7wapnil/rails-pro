module Customers
  class RegistrationService < ApplicationService
    def initialize(customer_data = {}, request = nil)
      @customer_data = customer_data
      @request = request
    end

    def call
      customer = Customer.create!(@customer_data)
      track_registration(customer)
      send_activation_email(customer)
      customer
    end

    private

    def track_registration(customer)
      customer.log_event :customer_signed_up, customer
      return if @request.nil?

      customer.update_tracked_fields!(@request)
    end

    def send_activation_email(customer)
      ArcanebetMailer
        .with(customer: customer)
        .account_activation_mail
        .deliver_now
    end
  end
end
