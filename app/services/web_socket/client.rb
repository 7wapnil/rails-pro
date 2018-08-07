module WebSocket
  class Client
    include Singleton

    def emit(event, data = {})
      reset_connection if connection.dead?
      connection.connect unless connection.established?

      connection.emit(event, data)
    end

    def connection
      @connection ||= SocketIOConnection.new(ENV['WEBSOCKET_URL'])
    end

    def reset_connection
      @connection = nil
    end
  end
end
