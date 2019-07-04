module Customers
  class RegistrationService < ApplicationService
    def initialize(customer_data = {}, request = nil)
      @customer_data = customer_data
      @request = request
    end

    def call
      ActiveRecord::Base.transaction do
        @customer = Customer.create!(prepared_attributes(customer_data))
        attach_wallet!(customer)
      end

      track_registration(customer)
      send_email_verification_email(customer)

      customer
    end

    private

    attr_reader :currency_code, :customer_data, :request, :customer

    def track_registration(customer)
      customer.log_event :customer_signed_up, customer
      return if request.nil?

      customer.update_tracked_fields!(request)
    end

    def send_email_verification_email(customer)
      ArcanebetMailer
        .with(customer: customer)
        .email_verification_mail
        .deliver_later
    end

    def prepared_attributes(attrs)
      attrs.transform_keys! do |key|
        key.to_s.underscore.to_sym
      end

      @currency_code = attrs.delete(:currency)

      attrs.merge(address_attributes:
                    attrs.extract!(:country, :city, :street_address,
                                   :state, :zip_code))
    end

    def attach_wallet!(customer)
      Wallets::FindOrCreate.call(customer: customer, currency: currency)
    end

    def currency
      Currency.find_by_code!(currency_code)
    end
  end
end
