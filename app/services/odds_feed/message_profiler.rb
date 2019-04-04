module OddsFeed
  class MessageProfiler
    include ActiveModel::Model
    include GlobalID::Identification

    PROFILER_ATTRIBUTES =
      %i[uuid event_external_id uof_message_registered_at].freeze

    LOGGABLE_STATES = %i[
      uof_message_registered_at
      worker_started_at
      web_socket_emit_initiated_at
      worker_ended_at
      action_cable_prepares_delivery_at
    ].freeze

    PROFILER_MESSAGE_TYPE_IDENTIFIER = 'profiler'.freeze

    attr_accessor(*PROFILER_ATTRIBUTES)

    def initialize(opts = {})
      @uuid = (opts && opts[:uuid]) || SecureRandom.uuid

      super
    end

    class << self
      def deserialize(serialized)
        new(JSON.parse(serialized.to_s))
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

    def store_properties(properties = {})
      properties.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      self
    end

    def trace_profiler_event(state_name)
      # TODO: TBC Restrict states to avoid mess in Kibana
      logger_message = {
        type: PROFILER_MESSAGE_TYPE_IDENTIFIER,
        uuid: uuid,
        event_external_id: event_external_id,
        state_name: state_name
      }
      # TODO: Make it switchable
      logger_message[:duration] = message_duration_calculation
      Rails.logger.info(logger_message.compact)
      self
    end

    private

    def message_duration_calculation
      return unless uof_message_registered_at

      (Time.current.to_f * 1000).round - uof_message_registered_at
    end
  end
end
