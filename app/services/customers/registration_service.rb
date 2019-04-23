module Customers
  class RegistrationService < ApplicationService
    def initialize(customer_data = {}, request = nil)
      @customer_data = customer_data
      @request = request
    end

    def call
      customer = Customer.create!(prepared_attributes(@customer_data))
      track_registration(customer)
      send_email_verification_email(customer)
      customer
    end

    private

    def track_registration(customer)
      customer.log_event :customer_signed_up, customer
      return if @request.nil?

      customer.update_tracked_fields!(@request)
    end

    def send_email_verification_email(customer)
      ArcanebetMailer
        .with(customer: customer)
        .email_verification_mail
        .deliver_later
    end

    def prepared_attributes(attrs)
      attrs.symbolize_keys!
      attrs.merge(address_attributes:
                    attrs.extract!(:country, :city, :street_address,
                                   :state, :zip_code))
    end
  end
end
