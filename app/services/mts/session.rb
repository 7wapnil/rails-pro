module Mts
  class Session
    include Singleton

    MTS_MQ_CONNECTION_PORT = 5671

    BUNNY_CONNECTION_EXCEPTIONS = [
      Bunny::NetworkFailure,
      Bunny::TCPConnectionFailed,
      Bunny::TCPConnectionFailedForAllHosts,
      Bunny::PossibleAuthenticationFailureError
    ].freeze

    def opened_connection
      return connection if connection_open?

      start_connection
    end

    def connection
      @connection ||= Bunny.new(default_config)
    end

    private

    delegate :open?, to: :connection, prefix: true, allow_nil: true

    def start_connection
      connection.start
    rescue *BUNNY_CONNECTION_EXCEPTIONS => error
      update_mts_connection_state

      raise error.class
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
        network_recovery_interval: 20
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
