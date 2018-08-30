module WebSocket
  class Client
    include Singleton

    def emit!(event, data = {})
      Rails.logger.info "Sending websocket event '#{event}', data: #{data}"
      message = ActiveSupport::JSON.encode(event: event, data: data)
      connection.publish(channel_name, message)
    end

    def emit(event, data = {})
      emit!(event, data)
    rescue StandardError => e
      Rails.logger.error e
      false
    end

    def connection
      @connection ||= Redis.new(url: ENV['REDIS_URL'])
    end

    def reset_connection
      @connection = nil
    end

    def channel_name
      'events'
    end
  end
end
