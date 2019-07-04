module Customers
  class RegistrationService < ApplicationService
    def initialize(customer_data = {}, request = nil)
      @customer_data = customer_data
      @request = request
    end

    def call
      registration_form = Forms::Registration.new(customer_data: customer_data)
      registration_form.validate!

      ActiveRecord::Base.transaction do
        registration_form.customer.save!
        registration_form.wallet.save!
      end

      @customer = registration_form.customer
      track_registration(customer)
      send_email_verification_email(customer)

      customer
    end

    private

    attr_reader :customer_data, :request, :customer

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
  end
end
