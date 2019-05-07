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

      log :info,
          message: 'Event not found in database',
          event_id: @external_id

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
      find_event
    end

    def crawling_forced?
      return false unless @options[:force].present?

      log :debug,
          message: 'Forced mode enabled, event will be updated from API'

      true
    end
  end
end
