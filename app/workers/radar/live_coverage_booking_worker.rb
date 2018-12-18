module Radar
  class LiveCoverageBookingWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def perform(event_external_id)
      super()
      log_job_message(
        :info, "Booking event #{event_external_id} for live coverage"
      )

      OddsFeed::Radar::LiveBookingService.call(event_external_id)
    end
  end
end
