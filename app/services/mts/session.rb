module Mts
  class Session
    MTS_MQ_CONNECTION_PORT = 5671
    BUNNY_EXCEPTIONS = [Bunny::NetworkFailure,
                        Bunny::TCPConnectionFailed,
                        Bunny::PossibleAuthenticationFailureException].freeze

    def initialize(config = nil)
      # TODO: Validate config format for custom input
      @config = config || default_config
      @session_recovery = SessionRecovery.new
    end

    def connection
      @connection ||= Bunny.new(@config)
    end

    def opened_connection
      connection.open? ? connection : start_connection
    end

    def within_connection
      yield(opened_connection)
    end

    private

    def start_connection
      connection.start
    rescue *BUNNY_EXCEPTIONS
      @session_recovery.recover_from_network_failure!
      @session_recovery.register_failure!
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
  end
end
