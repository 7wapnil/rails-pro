# frozen_string_literal: true

module Mts
  class Session
    include Singleton

    MTS_MQ_CONNECTION_PORT = 5671
    MAX_CONNECTION_ATTEMPTS = 5
    RECONNECTION_DELAY = 0.5

    BUNNY_CONNECTION_EXCEPTIONS = [
      Bunny::NetworkFailure,
      Bunny::TCPConnectionFailed,
      Bunny::TCPConnectionFailedForAllHosts,
      Bunny::PossibleAuthenticationFailureError
    ].freeze

    NETWORK_CONNECTION_EXCEPTIONS = [
      OpenSSL::SSL::SSLErrorWaitReadable,
      IOError,
      Errno::ECONNRESET
    ].freeze

    def opened_connection
      lock.synchronize do
        @connection_attempts = 0

        break connection if connection_open?

        start_connection!
      end
    end

    def connection
      @connection ||= Bunny.new(default_config)
    end

    private

    attr_reader :connection_attempts

    delegate :open?, to: :connection, prefix: true, allow_nil: true

    def start_connection!
      connection.start
    rescue *NETWORK_CONNECTION_EXCEPTIONS
      update_mts_connection_state

      @connection_attempts += 1
      sleep RECONNECTION_DELAY

      retry unless connection_attempts > MAX_CONNECTION_ATTEMPTS

      raise 'MTS connection cannot be established'
    rescue *BUNNY_CONNECTION_EXCEPTIONS => error
      update_mts_connection_state

      raise error.class
    end

    def lock
      @lock ||= Mutex.new
    end

    def default_config
      {
        host: ENV['MTS_MQ_HOST'],
        vhost: ENV['MTS_MQ_VHOST'],
        port: MTS_MQ_CONNECTION_PORT || ENV['MTS_MQ_PORT'],
        user: ENV['MTS_MQ_USER'],
        password: ENV['MTS_MQ_PASSWORD'],
        ssl: true,
        verify_peer: true,
        verify_peer_name: false,
        allow_self_signed: false,
        network_recovery_interval: 20,
        heartbeat: 30
      }
    end

    def update_mts_connection_state
      MtsConnection.instance.recovering!

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
