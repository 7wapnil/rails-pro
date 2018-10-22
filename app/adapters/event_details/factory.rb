module EventDetails
  class Factory
    def self.build(event)
      case provider(event)
      when :radar
        EventDetails::Radar.new(event)
      else
        raise NotImplementedError, 'Unknown data provider for event details'
      end
    end

    # TODO: implement provider definition logic when new provider appears
    def self.provider(_event)
      :radar
    end
  end
end
