module EventsManager
  class EventLoader < BaseEntityLoader
    def call
      local_event || crawled_event
    end

    private

    def local_event
      return nil if crawling_forced?

      event = ::Event.find_by(external_id: @external_id)
      return event if event

      log :info,
          message: 'Event not found in database',
          event_id: @external_id

      nil
    end

    def crawled_event
      ::EventsManager::EventFetcher.call(@external_id)
    end

    def crawling_forced?
      return false unless @options[:force].present?

      log :debug,
          message: 'Forced mode enabled, event will be updated from API'

      true
    end
  end
end
