module Account
  class SendPasswordResetService < ApplicationService
    attr_reader :customer

    def initialize(customer)
      @customer = customer
      @retries = 3
    end

    def call
      return unless customer&.email_verified?

      update_reset_password_token
      send_reset_password_mail
    end

    private

    def update_reset_password_token
      _raw, token =
        Devise.token_generator.generate(Customer, :reset_password_token)

      customer.update!(
        reset_password_token: token,
        reset_password_sent_at: Time.zone.now
      )
    rescue ActiveRecord::RecordNotUnique
      @retries -= 1
      retry unless @retries.negative?
    end

    def send_reset_password_mail
      ArcanebetMailer
        .with(customer: customer)
        .reset_password_mail
        .deliver_later
    end
  end
end
