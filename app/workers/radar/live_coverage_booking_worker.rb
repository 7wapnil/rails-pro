module Radar
  class LiveCoverageBookingWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def perform(event_external_id)
      OddsFeed::Radar::LiveBookingService.call(event_external_id)
    end
  end
end
