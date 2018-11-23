class ApplicationState
  attr_reader :status
  attr_reader :live_connected,
              :pre_live_connected

  STATE_STORAGE_KEY = :app_state

  STATUSES = {
    inactive: 0,
    active: 1
  }.freeze

  def self.instance
    @instance ||= new
  end

  def initialize
    @storage = Rails.cache
    @status = :active
    read_app_state
  end

  def live_connected=(status)
    @live_connected = status
    store_app_state
  end

  def pre_live_connected=(status)
    @pre_live_connected = status
    store_app_state
  end

  def status=(status)
    raise "No status '#{status}'" unless STATUSES.key?(status)

    @status = status
    WebSocket::Client.instance.emit(WebSocket::Signals::APP_STATE_UPDATED,
                                    status: status)
  end

  private

  def state_attributes
    { live_connected: @live_connected,
      pre_live_connected: @pre_live_connected }
  end

  def read_app_state
    state = @storage.read(STATE_STORAGE_KEY)
    @live_connected = state.nil? ? true : state[:live_connected]
    @pre_live_connected = state.nil? ? true : state[:pre_live_connected]
    update_notify
  end

  def store_app_state
    @storage.write(STATE_STORAGE_KEY, state_attributes)
    update_notify
  end

  def update_notify
    WebSocket::Client
      .instance
      .emit(WebSocket::Signals::APP_STATE_UPDATED, state_attributes)
  end
end
