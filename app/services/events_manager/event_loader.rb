module EventsManager
  class EventLoader < BaseEntityLoader
    def call
      local_event || crawled_event
    end

    private

    def local_event
      return nil if crawling_forced?

      event = find_event
      return event if event

      log :debug, "Event '#{@external_id}' not found"
      nil
    end

    def find_event
      query = Event
      query.includes(includes) if includes.any?
      query.find_by(external_id: @external_id)
    end

    def includes
      @options[:includes].to_a
    end

    def crawled_event
      ::EventsManager::EventFetcher.call(@external_id)
    end

    def crawling_forced?
      return false unless crawling_force_enabled?

      log :debug, 'Forced mode enabled, will be updated from API'
      true
    end

    # Temporary solution to keep current usage compatible
    # @todo Keep :force option usage only after integration
    def crawling_force_enabled?
      @options[:force].present? || @options[:check_existence] == false
    end
  end
end
