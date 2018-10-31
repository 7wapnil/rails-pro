class ApplicationState
  include Singleton

  attr_reader :status
  attr_accessor :flags

  STATUSES = {
    inactive: 0,
    active: 1
  }.freeze

  def initialize
    @status = :active
    @flags = []
  end

  def status=(status)
    raise "No status '#{status}'" unless STATUSES.key?(status)

    @status = status
    WebSocket::Client.instance.emit(WebSocket::Signals::APP_STATE_UPDATED,
                                    status: status)
  end
end
