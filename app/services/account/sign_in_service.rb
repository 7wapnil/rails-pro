module Account
  # rubocop:disable Metrics/ClassLength
  class SignInService
    include Recaptcha::Verify

    IMPORTED_CUSTOMER_RESET_INTERVAL = 15

    delegate :invalid_login_attempt!, :valid_password?,
             :suspicious_login?, :encrypted_password,
             :reset_password_sent_at,
             to: :customer, allow_nil: true

    def initialize(customer:, params:, request:)
      @customer = customer
      @password = params[:password]
      @captcha = params[:captcha]
      @identity = params[:login]
      @login_request = request
    end

    def captcha_invalid?
      (captcha || suspicious_login?) && !captcha_verified?
    end

    def invalid_captcha!
      invalid_login_attempt!

      msg = I18n.t('recaptcha.errors.verification_failed')

      login_tracker.call(success: false, failure_reason: msg)

      GraphQL::ExecutionError.new(msg)
    end

    def invalid_password?
      !valid_password?(password)
    end

    def invalid_login!
      invalid_login_attempt!

      msg = I18n.t('errors.messages.wrong_login_credentials')

      login_tracker.call(success: false, failure_reason: msg)

      GraphQL::ExecutionError.new(msg)
    end

    def imported_customer_first_login?
      empty_encrypted_password?
    end

    def reset_password!
      send_reset_password! unless recent_reset_email?

      login_tracker.call(
        success: false,
        failure_reason: 'Newly imported customer. Password reset required'
      )

      GraphQL::ExecutionError.new(
        I18n.t(
          'errors.messages.imported_customer_first_login',
          email: obfuscate_email(customer.email)
        )
      )
    end

    def login_response
      return account_locked_response if customer.locked?

      login_tracker.call(success: true)

      customer.log_event(:customer_signed_in)
      response
    end

    private

    attr_reader :customer, :password, :captcha, :identity, :login_request

    def login_tracker
      @login_tracker ||= LoginActivities::TrackLogin.new(
        customer: customer,
        identity: identity,
        request: login_request
      )
    end

    # Need to mock `request` to make `verify_recaptcha` works
    def request; end

    def captcha_verified?
      verify_recaptcha(response: captcha.to_s, skip_remote_ip: true)
    end

    def account_locked_message
      I18n.t(
        'errors.messages.account_locked.default',
        additional_info: additional_lock_info
      )
    end

    def additional_lock_info
      account_lock_time = customer.locked_until
      return unless account_lock_time

      I18n.t(
        'errors.messages.account_locked.additional_info.until',
        until_date: I18n.l(customer.locked_until, format: :default)
      )
    end

    def account_locked_response
      customer.log_event(:locked_customer_sign_in_attempt)

      login_tracker.call(success: false,
                         failure_reason: account_locked_message)

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

    def empty_encrypted_password?
      encrypted_password&.empty?
    end

    def send_reset_password!
      Account::SendPasswordResetService.call(customer: customer)
    end

    def obfuscate_email(email)
      email
        .split('@')
        .map { |word| "#{word.first(2)}...#{word.last}" }
        .join('@')
    end

    def recent_reset_email?
      return unless customer.reset_password_sent_at

      (Time.zone.now - customer.reset_password_sent_at) <
        IMPORTED_CUSTOMER_RESET_INTERVAL.minutes
    end
  end
  # rubocop:enable Metrics/ClassLength
end
