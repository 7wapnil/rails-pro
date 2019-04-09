# frozen_string_literal: true

module Mts
  class ReconnectionWorker < ApplicationWorker
    def perform
      return if MtsConnection.instance.status == MtsConnection::HEALTHY

      MtsConnection.instance.healthy! if successful_reconnection?

      emit_application_state
    end

    private

    def successful_reconnection?
      ::Mts::SingleSession.instance.session.opened_connection
    end

    def emit_application_state
      WebSocket::Client.instance
                       .trigger_application_state_update(
                         MtsConnection.instance.status
                       )
    end
  end
end
