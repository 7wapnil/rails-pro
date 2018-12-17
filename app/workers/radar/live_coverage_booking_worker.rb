module Radar
  class LiveCoverageBookingWorker < ApplicationWorker
    include ::QueueName

    sidekiq_options queue: queue_name

    def perform(event_external_id)
      super()

      event = Event.find_by!(external_id: event_external_id)

      log_job_message(
        :info, "Booking event #{event_external_id} for live coverage"
      )

      # booking_response =
      #   OddsFeed::Radar::Client.new.book_live_coverage(event_external_id)
      #
      # return unless booking_response['response']['response_code'] == 'OK'

      event.update_attributes!(traded_live: true)
    end
  end
end
