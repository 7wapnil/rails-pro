module LoginAttemptable
  extend ActiveSupport::Concern

  LOGIN_ATTEMPTS_CAP = 3

  included do
    def valid_for_authentication?
      return super unless persisted?

      return valid_login_attempt! if super

      invalid_login_attempt!
    end

    def valid_login_attempt!
      update_columns(failed_attempts: 0)

      true
    end

    def invalid_login_attempt!
      update_columns(failed_attempts: failed_attempts + 1)

      # FIXME: re-enable the notification when the attack issue resolved
      # notify_account_owner if attempts_just_exceeded?

      false
    end

    def attempts_just_exceeded?
      failed_attempts == LOGIN_ATTEMPTS_CAP + 1
    end

    def suspicious_login?
      failed_attempts >= LOGIN_ATTEMPTS_CAP
    end

    private

    def notify_account_owner
      CustomerActivityMailer.suspicious_login(email).deliver_now
    end
  end
end
