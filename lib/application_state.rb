class ApplicationState
  include Singleton

  attr_reader :status
  attr_reader :flags

  STATUSES = {
    inactive: 0,
    active: 1
  }.freeze

  ALLOWED_FLAGS = Radar::Producer.failure_flag_keys

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

  def enable_flag(swag)
    raise ArgumentError unless ALLOWED_FLAGS.include? swag
    return if @flags.include? swag

    @flags << swag
    flags_update_notify!
    @flags
  end

  def disable_flag(swag)
    raise ArgumentError unless ALLOWED_FLAGS.include? swag
    return unless @flags.include? swag

    @flags.delete(swag)
    flags_update_notify!
    @flags
  end

  private

  def flags_update_notify!
    WebSocket::Client.instance.emit(WebSocket::Signals::APP_STATE_UPDATED,
                                    flags: flags)
  end
end
