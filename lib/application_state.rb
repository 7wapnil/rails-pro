class ApplicationState
  class StateModel
    include ::GlobalID::Identification
    include ActiveModel::Model

    STATE_STORAGE_KEY = :app_state

    attr_reader :id
    attr_accessor :live_connected,
                  :pre_live_connected

    def initialize(attributes = {})
      @id = 1
      @live_connected = true
      @pre_live_connected = true
      super(attributes)
    end

    def attributes
      { live_connected: @live_connected,
        pre_live_connected: @pre_live_connected }
    end

    def save
      Rails.cache.write(STATE_STORAGE_KEY, attributes)
    end

    def update(attributes = {})
      assign_attributes(attributes)
      save
    end

    def self.find(_id)
      state = Rails.cache.read(STATE_STORAGE_KEY)
      new(state || {})
    end

    def self.delete
      Rails.cache.delete(STATE_STORAGE_KEY)
    end
  end

  attr_reader :status

  STATUSES = {
    inactive: 0,
    active: 1
  }.freeze

  def self.instance
    @instance ||= new
  end

  def initialize
    @status = :active
  end

  def state
    StateModel.find(1)
  end

  def live_connected
    state.live_connected
  end

  def live_connected=(status)
    state.update(live_connected: status)
  end

  def pre_live_connected
    state.pre_live_connected
  end

  def pre_live_connected=(status)
    state.update(pre_live_connected: status)
  end

  def status=(status)
    raise "No status '#{status}'" unless STATUSES.key?(status)

    @status = status
  end
end
