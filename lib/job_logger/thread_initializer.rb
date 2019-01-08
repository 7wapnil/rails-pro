module JobLogger
  module ThreadInitializer
    def populate_job_info_to_thread
      Thread.current[:start_time] = Time.now.to_f
      Thread.current[:job_id]     = jid
    end

    def populate_enqueued_at_to_thread
      Thread.current[:enqueued_at] = @enqueued_at
    end
  end
end
