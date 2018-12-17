module JobLogger
  module Initializer
    protected

    def populate_job_info_to_thread
      Thread.current[:enqueued_at] = @enqueued_at
      Thread.current[:start_time]  = Time.now.to_f
      Thread.current[:job_id]      = jid
    end
  end
end
