module Users
  class SignInService
    FIRST_ATTEMPT = 1

    attr_reader :email, :last_login, :attempts

    delegate :invalid_login_attempt!, to: :login_user, allow_nil: true

    def initialize(model:, email:, session:)
      @model      = model
      @email      = email
      @attempts   = session[:attempts].to_i
      @last_login = session[:last_login]
    end

    def login_user
      @login_user ||= model.find_for_authentication(email: email)
    end

    def calculate_attempts
      @attempts = same_login? ? attempts + 1 : FIRST_ATTEMPT
    end

    def suspicious?
      login_user&.suspicious_login? ||
        attempts >= LoginAttemptable::LOGIN_ATTEMPTS_CAP
    end

    private

    attr_reader :model

    def same_login?
      email == last_login
    end
  end
end
