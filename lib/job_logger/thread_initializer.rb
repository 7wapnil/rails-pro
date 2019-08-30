# frozen_string_literal: true

module JobLogger
  module ThreadInitializer
    EVENT_ID_PATTERN = 'event_id="([^"]*)"'
    PRODUCT_PATTERN = 'product="([0-9]*)"'
    TIMESTAMP_PATTERN = 'timestamp="([0-9]*)"'

    def populate_job_info_to_thread
      Thread.current[:start_time] = Time.now.to_f
      Thread.current[:job_id]     = jid
    end

    def populate_enqueued_at_to_thread
      Thread.current[:enqueued_at] = @enqueued_at
    end

    def populate_message_info_to_thread(payload)
      Thread.current[:event_id] = scan_for_event_id(payload)
      Thread.current[:message_timestamp] = scan_for_message_timestamp(payload)
      Thread.current[:event_producer_id] = scan_for_event_producer_id(payload)
      Thread.current[:message_producer_id] =
        scan_for_message_producer_id(payload)
    end

    def scan_for_event_id(payload)
      result = payload.scan(Regexp.new(EVENT_ID_PATTERN))
      return '' if result.empty?

      result[0][0]
    end

    def scan_for_message_producer_id(payload)
      result = payload.scan(Regexp.new(PRODUCT_PATTERN))
      return '' if result.empty?

      result[0][0]
    end

    def scan_for_message_timestamp(payload)
      result = payload.scan(Regexp.new(TIMESTAMP_PATTERN))
      return '' if result.empty?

      result[0][0]
    end

    def scan_for_event_producer_id(payload)
      result = payload.scan(Regexp.new(EVENT_ID_PATTERN))
      return '' if result.empty?

      Event.find_by(external_id: result[0][0])&.producer_id
    end
  end
end
