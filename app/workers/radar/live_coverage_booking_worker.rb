module Radar
  class LiveCoverageBookingWorker
    include Sidekiq::Worker

    def perform(event_external_id)
      event = Event.find_by!(external_id: event_external_id)

      Rails.logger.info "Booking event #{event_external_id} for live coverage"

      booking_response =
        OddsFeed::Radar::Client.new.book_live_coverage(event_external_id)

      return unless booking_response['response']['response_code'] == 'OK'

      event.update_attributes!(traded_live: true)
    end
  end
end
