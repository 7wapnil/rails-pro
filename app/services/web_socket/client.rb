module WebSocket
  class Client
    attr_reader :connection

    def initialize(connection)
      @connection = connection
    end

    def emit(event, data = {})
      @connection.connect if @connection.dead?
      @connection.emit(event, data)
    end
  end
end
