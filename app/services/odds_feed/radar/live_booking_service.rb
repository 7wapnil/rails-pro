module OddsFeed
  module Radar
    class LiveBookingService < ApplicationService
      include JobLogger

      BOOKABLE = 'bookable'.freeze

      def initialize(event_external_id)
        @event_external_id = event_external_id
      end

      def call
        return                    if event.traded_live
        return update_event       if replay?
        return book_live_coverage if bookable?

        log_job_message(:info, unbookable_message)
      end

      def update_event
        msg = "Updating traded live flag for #{event.external_id}"
        log_job_message(:debug, msg)

        event.update_attributes!(traded_live: true)
      end

      def book_live_coverage
        response = api_client.book_live_coverage(event.external_id)['response']
        return update_event if response['response_code'] == 'OK'

        raise ::OddsFeed::InvalidResponseError, [response['message'],
                                                 event.external_id]
      end

      private

      def event
        @event ||= Event.find_by!(external_id: @event_external_id)
      end

      def api_client
        @api_client ||= OddsFeed::Radar::Client.new
      end

      def bookable?
        event.payload['liveodds'] == BOOKABLE
      end

      def unbookable_message
        "'liveodd' for event #{event.external_id} is not '#{BOOKABLE}'"
      end

      def replay?
        ENV['RADAR_MQ_LISTEN_ALL'] == 'true'
      end
    end
  end
end
