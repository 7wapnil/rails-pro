module Mts
  class Session
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
    rescue Bunny::TCPConnectionFailed => e
      masked_config =
        @config.tap { |c| c[:password] = '****' }
      log_msg = {
        error: e,
        config: masked_config
      }
      Rails.logger.error(log_msg.to_json)
      raise e
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
        allow_self_signed: false,
        network_recovery_interval: 20
      }
    end
  end
end
