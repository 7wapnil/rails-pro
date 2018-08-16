module WebSocket
  class SocketIOConnection
    DEFAULT_PORTS = { ws: 80, wss: 443 }.freeze

    attr_reader :url, :thread

    def initialize(base_url)
      @url  = "#{base_url}/socket.io/?transport=websocket"
      @uri  = URI.parse(url)
      @uri.port ||= DEFAULT_PORTS[@uri.scheme]
      @dead = false
      @established = false

      Rails.logger.debug "Build client, url: #{@url}, port: #{@uri.port}"
    end

    def connect
      @driver = WebSocket::Driver.client(self, protocols: ['websocket'])
      set_handlers

      socket = tcp
      @dead = false

      @thread = Thread.new do
        @driver.parse(socket.read(1)) until @dead
      end
      @driver.start
    end

    def established?
      @established
    end

    def close
      @driver.close
    end

    def dead?
      @dead
    end

    def emit(event, data = {})
      message = ['message', { event: event, data: data }]
      data = ActiveSupport::JSON.encode(message)
      @driver.text("42#{data}")
    end

    def write(data)
      tcp.write(data)
    end

    private

    def tcp
      @tcp ||= TCPSocket.new(@uri.host, @uri.port)
    end

    def set_handlers
      set_open_hanlder
      set_error_handler
      set_close_handler
    end

    def set_open_hanlder
      @driver.on(:open) do
        Rails.logger.debug 'WebSocket connection opened'
        @established = true
      end
    end

    def set_message_handler
      @driver.on(:message) do |event|
        Rails.logger.info "Message received: #{event.data}"
      end
    end

    def set_error_handler
      @driver.on(:error) do |error|
        Rails.logger.error "ERROR: #{error}"
      end
    end

    def set_close_handler
      @driver.on(:close) do |event|
        Rails.logger.debug "Closing connection: #{event.code}, #{event.reason}"
        @dead = true
        @thread.kill
      end
    end
  end
end
