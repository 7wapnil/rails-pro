# frozen_string_literal: true

module Mts
  class ReconnectionWorker < ApplicationWorker
    def perform
      return if MtsConnection.instance.healthy?

      MtsConnection.instance.healthy! if successful_reconnection?

      emit_application_state
    end

    private

    def successful_reconnection?
      ::Mts::SingleSession.instance.session.opened_connection.present?
    end

    def emit_application_state
      WebSocket::Client.instance
                       .trigger_mts_connection_status_update(
                         MtsConnection.instance
                       )
    end
  end
end
