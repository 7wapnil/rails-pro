module WebSocket
  class Client
    include Singleton

    attr_writer :connection

    def emit(event, data = {})
      raise 'No connection defined' if @connection.nil?
      @connection.connect if @connection.dead?
      @connection.emit(event, data)
    end
  end
end
