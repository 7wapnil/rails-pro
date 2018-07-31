class WebSocketClient
  include Singleton

  DEFAULT_PORTS = { ws: 80, wss: 443 }.freeze

  attr_reader :url, :thread

  def initialize
    @url  = "#{ENV['WEBSOCKET_URL']}/socket.io/?transport=websocket"
    @uri  = URI.parse(url)
    @port = @uri.port || DEFAULT_PORTS[@uri.scheme]

    @tcp  = TCPSocket.new(@uri.host, @port)
    @dead = false

    Rails.logger.debug "Build websocket client, url: #{@url}, port: #{@port}"

    connect
  end

  def connect
    @driver = WebSocket::Driver.client(self, protocols: ['websocket'])
    set_listeners

    @thread = Thread.new do
      @driver.parse(@tcp.read(1)) until @dead
    end
    @driver.start
  end

  def send(message)
    Rails.logger.info "Sending message: #{message}"
    data = ActiveSupport::JSON.encode(['message', { message: message }])
    msg = "42#{data}"
    Rails.logger.debug "Compiled message: #{msg}"
    @driver.text(msg)
  end

  def write(data)
    @tcp.write(data)
  end

  def close
    Rails.logger.debug 'Closing connection'
    @driver.close
  end

  def finalize(event)
    p [:close, event.code, event.reason, @driver.headers]
    @dead = true
    @thread.kill
  end

  private

  def set_handlers
    set_open_hanlder
    set_message_handler
    set_error_handler
    set_close_handler
  end

  def set_open_hanlder
    @driver.on(:open) do
      Rails.logger.debug 'Connection opened'
    end
  end

  def set_message_handler
    @driver.on(:message) do |event|
      Rails.logger.info "Message received: #{event.data}"
    end
  end

  def set_error_handler
    @driver.on(:error) do |error|
      Rails.logger.error error
    end
  end

  def set_close_handler
    @driver.on(:close) do |event|
      Rails.logger.debug 'Closing connection'
      finalize(event)
    end
  end
end
