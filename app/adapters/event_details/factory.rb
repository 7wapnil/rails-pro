module EventDetails
  class Factory
    # TODO: implement provider definition logic when new provider appears
    def self.build(event)
      provider(event).new(event)
    end

    def self.provider(_event)
      return EventDetails::Radar

      # rubocop:disable Lint/UnreachableCode
      raise NotImplementedError, 'Unknown data provider for event details'
      # rubocop:enable Lint/UnreachableCode
    end
  end
end
