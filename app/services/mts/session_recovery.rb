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

      update_mts_connection_state

      false
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

    def update_mts_connection_state
      ApplicationState
        .find_or_create_by(type: MtsConnection.name)
        .recovering!

      emit_application_state
    end

    def emit_application_state
      WebSocket::Client.instance
                       .trigger_mts_connection_status_update(
                         MtsConnection.instance
                       )
    end
  end
end
