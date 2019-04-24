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

      Rails.logger.debug "Event '#{@external_id}' not found"
      nil
    end

    def crawled_event
      ::EventsManager::EventCrawler.call(@external_id)
    end

    def crawling_forced?
      return false unless crawling_force_enabled?

      Rails.logger.debug 'Forced mode enabled, event will be updated from API'
      true
    end

    # Temporary solution to keep current usage compatible
    # @todo Keep :force option usage only after integration
    def crawling_force_enabled?
      @options[:force] || @options[:check_existence] == false
    end
  end
end
