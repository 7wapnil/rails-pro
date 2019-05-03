module Radar
  class LiveCoverageBookingWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def perform(event_external_id)
      log_job_message(:info, message: 'Booking event for live coverage',
                             event_id: event_external_id)

      OddsFeed::Radar::LiveBookingService.call(event_external_id)
    end
  end
end
