module OddsFeed
  class MessageProfiler
    include ActiveModel::Model
    include GlobalID::Identification

    PROFILER_ATTRIBUTES =
      %i[uuid event_external_id].freeze

    LOGGABLE_STATES = %i[
      uof_message_origin_time
      uof_message_registered_at
      worker_started_at
      web_socket_emit_initiated_at
      action_cable_prepares_delivery_at
    ].freeze

    attr_accessor(*PROFILER_ATTRIBUTES)

    def initialize(opts = {})
      @uuid = opts[:uuid] || SecureRandom.uuid

      super
    end

    class << self
      def deserialize(serialized)
        new(JSON.parse(serialized))
      end

      alias find deserialize
    end

    def dump
      JSON.dump(to_h)
    end

    alias id dump

    def to_h
      Hash[PROFILER_ATTRIBUTES.map { |attribute| [attribute, send(attribute)] }]
        .compact
    end

    def to_s
      to_h.to_s
    end

    # TODO: normalize time_to_log format
    def log_state(state_name, time_to_log = nil)
      # TODO: TBC Restrict states to avoid mess in Kibana
      # TODO: TBC Remove timestamp if correlates with Kibana Timestamp
      logger_message = {
        type: 'profiler',
        uuid: uuid,
        event_external_id: event_external_id,
        state_name: state_name,
        timestamp: time_to_log || measure
      }
      Rails.logger.info(logger_message)
      self
    end

    private

    # TODO: TBC Best format to log time
    def measure
      Time.current.to_f.to_s
    end
  end
end
