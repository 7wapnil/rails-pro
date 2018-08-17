module WebSocket
  class Client
    include Singleton

    def emit!(event, data = {})
      reset_connection if connection.dead?
      connection.connect unless connection.established?

      Rails.logger.info "Sending websocket event '#{event}', data: #{data}"
      connection.emit(event, data)
    end

    def emit(event, data = {})
      emit!(event, data)
    rescue => e
      Rails.logger.error e
      false
    end

    def connection
      @connection ||= SocketIOConnection.new(ENV['WEBSOCKET_URL'])
    end

    def reset_connection
      @connection = nil
    end
  end
end
