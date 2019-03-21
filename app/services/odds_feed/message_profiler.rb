module OddsFeed
  class MessageProfiler
    include ActiveModel::Model
    include GlobalID::Identification

    def id
      to_h
    end

    def self.find(hash)
      new(hash)
    end

    PROFILED_ATTRIBUTES =
      :enqueued_at, :event_created_at,
        :markets_generated_at, :websocket_emitted_at

    attr_accessor *PROFILED_ATTRIBUTES

    def enqueue
      new(enqueued_at: measure)
    end

    def profile!(attribute)
      raise unless PROFILED_ATTRIBUTES.include? attribute

      send("#{attribute.to_s}=", measure)
    end

    # TODO: Combine more optimal way
    def to_h
      hash = {}
      PROFILED_ATTRIBUTES.map do |attribute|
        hash[attribute] = send(attribute)
      end
      hash.compact
    end

    def to_s
      to_h.to_s
    end

    private

    def measure
      Time.current.to_f.to_s
    end
  end
end
