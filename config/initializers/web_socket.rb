# Initializes web socket client with socket.io
# connection adapter

WebSocket::Client.instance.connection = WebSocket::SocketIOConnection.new(
  ENV['WEBSOCKET_URL']
)
