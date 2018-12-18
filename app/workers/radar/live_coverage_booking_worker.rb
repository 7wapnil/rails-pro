module Radar
  class LiveCoverageBookingWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def perform(event_external_id)
      super()

      log_msg = "Booking event #{event_external_id} for live coverage"
      log_job_message(:info, log_msg)

      OddsFeed::Radar::LiveBookingService.call(event_external_id)
    end
  end
end
