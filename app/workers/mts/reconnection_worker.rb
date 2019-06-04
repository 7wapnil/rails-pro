# frozen_string_literal: true

module Mts
  class ReconnectionWorker < ApplicationWorker
    sidekiq_options queue: :mts

    def perform
      return if MtsConnection.instance.healthy?

      MtsConnection.instance.healthy! if successful_reconnection?

      emit_application_state
    end

    private

    def successful_reconnection?
      ::Mts::Session.instance.opened_connection.present?
    end

    def emit_application_state
      WebSocket::Client.instance
                       .trigger_mts_connection_status_update(
                         MtsConnection.instance
                       )
    end
  end
end
