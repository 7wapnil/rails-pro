module Customers
  class VerificationService < ApplicationService
    attr_reader :current_user, :customer, :status_params

    def initialize(current_user, customer, status_params)
      @current_user = current_user
      @customer = customer
      @status_params = status_params
    end

    def call
      update_customer_status
      log_customer_status_change

      return unless customer_needs_verification_email?

      send_verification_email
      set_verification_sent
    end

    private

    def update_customer_status
      customer.update!(status_params)
    end

    def log_customer_status_change
      current_user.log_event(
        customer.verified ? :customer_verified : :customer_verification_revoked,
        nil,
        customer
      )
    end

    def customer_needs_verification_email?
      !customer.verification_sent &&
        customer.email_verified &&
        customer.verified
    end

    def send_verification_email
      ArcanebetMailer
        .with(customer: customer)
        .account_verification_mail
        .deliver_now
    end

    def set_verification_sent
      customer.update! verification_sent: true
    end
  end
end
