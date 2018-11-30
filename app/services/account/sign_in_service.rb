module Account
  class SignInService
    include Recaptcha::Verify

    delegate :invalid_login_attempt!, :valid_password?,
             :suspicious_login?,
             to: :customer, allow_nil: true

    def initialize(customer:, params:)
      @customer = customer
      @password = params[:password]
      @captcha  = params[:captcha]
    end

    def captcha_invalid?
      (captcha || suspicious_login?) && !captcha_verified?
    end

    def invalid_captcha!
      invalid_login_attempt!

      GraphQL::ExecutionError.new(
        I18n.t('recaptcha.errors.verification_failed')
      )
    end

    def invalid_password?
      !valid_password?(password)
    end

    def invalid_login!
      invalid_login_attempt!

      GraphQL::ExecutionError.new(
        I18n.t('errors.messages.wrong_login_credentials')
      )
    end

    def login_response
      return account_locked_response if customer.locked?

      customer.log_event(:customer_signed_in)
      response
    end

    private

    attr_reader :customer, :password, :captcha

    # Need to mock `request` to make `verify_recaptcha` works
    def request; end

    def captcha_verified?
      verify_recaptcha(response: captcha.to_s, skip_remote_ip: true)
    end

    def account_locked_message
      account_lock_time = customer.locked_until

      if account_lock_time.nil?
        return I18n.t('errors.messages.account_locked.default')
      end

      I18n.t(
        'errors.messages.account_locked.default',
        additional_info: I18n.t(
          'errors.messages.account_locked.additional_info.until',
          until_date: customer.locked_until.strftime(
            I18n.t('date.formats.default')
          )
        )
      )
    end

    def account_locked_response
      customer.log_event(:locked_customer_sign_in_attempt)

      GraphQL::ExecutionError.new(account_locked_message)
    end

    def response
      OpenStruct.new(user: customer, token: token)
    end

    def token
      JwtService.encode(
        id:       customer.id,
        username: customer.username,
        email:    customer.email
      )
    end
  end
end
