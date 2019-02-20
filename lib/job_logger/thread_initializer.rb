module JobLogger
  module ThreadInitializer
    EVENT_ID_PATTERN = 'event_id="([^"]*)"'.freeze

    def populate_job_info_to_thread
      Thread.current[:start_time] = Time.now.to_f
      Thread.current[:job_id]     = jid
    end

    def populate_enqueued_at_to_thread
      Thread.current[:enqueued_at] = @enqueued_at
    end

    def populate_event_id_to_thread(event_id)
      Thread.current[:event_id] = event_id
    end

    def event_id_scan(payload)
      result = payload.scan(Regexp.new(EVENT_ID_PATTERN))
      return '' if result.empty?

      result[0][0]
    end
  end
end
