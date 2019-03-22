module OddsFeed
  class MessageProfiler
    include ActiveModel::Model
    include GlobalID::Identification

    PROFILED_ATTRIBUTES =
      %i[enqueued_at event_created_at
         markets_generated_at websocket_emitted_at].freeze

    def id
      JSON.dump(to_h)
    end

    def self.find(serialized)
      new(JSON.parse(serialized))
    end

    attr_accessor(*PROFILED_ATTRIBUTES)

    def self.enqueue
      new.profile!(:enqueued_at)
    end

    def profile!(attribute)
      raise unless PROFILED_ATTRIBUTES.include? attribute

      send("#{attribute}=", measure)
      self
    end

    def to_h
      Hash[PROFILED_ATTRIBUTES.map { |attribute| [attribute, send(attribute)] }]
        .compact
    end

    def to_s
      to_h.to_s
    end

    def log!
      Rails.logger.info(type: 'profiler', profile: to_h)
    end

    private

    def measure
      Time.current.to_f.to_s
    end
  end
end
