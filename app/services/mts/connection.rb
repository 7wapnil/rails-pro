module Mts
  class Connection
    MTS_MQ_CONNECTION_PORT = 5671

    def initialize(config = nil)
      # TODO: Validate config format for custom input
      @config = config || default_config
    end

    def connection
      @connection ||= Bunny.new(@config)
    end

    def opened_connection
      connection.open? ? connection : connection.start
    end

    def within_connection
      yield(opened_connection)
    end

    private

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
        allow_self_signed: false
      }
    end
  end
end
