module Radar
  class LiveCoverageBookingWorker
    include Sidekiq::Worker

    def perform(event_external_id)
      Rails.logger.info "Booking event #{event_external_id} for live coverage"
      OddsFeed::Radar::Client.new.book_live_coverage(event_external_id)
    end
  end
end
