module Mts
  class SessionRecovery
    include JobLogger

    MTS_SESSION_FAILURE_KEY = :mts_session_failed_at

    def recover_from_network_failure!
      return if session_failed_at.blank?

      clear_session_failed_at
    end

    def register_failure!
      return if session_failed_at.present?

      timestamp = Time.zone.now
      update_session_failed_at(timestamp)
      log_job_message(:warn, "Mts session failed at: #{timestamp}")
    end

    private

    def session_failed_at
      Rails.cache.fetch(MTS_SESSION_FAILURE_KEY)
    end

    def update_session_failed_at(timestamp)
      Rails.cache.write(MTS_SESSION_FAILURE_KEY, timestamp)
    end

    def clear_session_failed_at
      Rails.cache.delete(MTS_SESSION_FAILURE_KEY)
    end
  end
end
