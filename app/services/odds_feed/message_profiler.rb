module OddsFeed
  class MessageProfiler
    include ActiveModel::Model
    include GlobalID::Identification

    PROFILER_ATTRIBUTES =
      %i[uuid event_external_id].freeze


    attr_accessor(*PROFILER_ATTRIBUTES)

    def initialize(opts = {})
      Rails.logger.info 'NEW PROFILER'
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

    def log_state(state_name)
      # TODO: Remove timestamp if correlates with Kibana Timestamp
      logger_message = {
        type: 'profiler',
        uuid: uuid,
        event_external_id: event_external_id,
        state_name: state_name,
        timestamp: measure
      }
      self
    end

    private

    def measure
      Time.current.to_f.to_s
    end
  end
end
