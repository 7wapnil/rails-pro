# frozen_string_literal: true

module Account
  class SendPasswordResetService < ApplicationService
    include Recaptcha::Verify

    def initialize(email:, captcha: nil)
      @email = email&.downcase&.strip
      @captcha = captcha
      @retries = 3
    end

    def captcha_invalid?
      captcha.nil? || !captcha_verified?
    end

    def invalid_captcha!
      GraphQL::ExecutionError.new(
        I18n.t('recaptcha.errors.verification_failed')
      )
    end

    def call
      return unless customer

      update_reset_password_token
      send_reset_password_mail

      @raw_token
    end

    def customer
      @customer ||= Customer.find_by('lower(email) = ?', email)
    end

    private

    attr_reader :email, :captcha

    # Need to mock `request` to make `verify_recaptcha` works
    def request; end

    def captcha_verified?
      verify_recaptcha(response: captcha.to_s, skip_remote_ip: true)
    end

    def update_reset_password_token
      @raw_token, token =
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
        .reset_password_mail(@raw_token)
        .deliver_later
    end
  end
end
