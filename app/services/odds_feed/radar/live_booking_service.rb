module OddsFeed
  module Radar
    class LiveBookingService < ApplicationService
      include JobLogger

      def initialize(event_external_id)
        log_job_message(
          :debug,
          'This service is deprecated in favor of CTRL based coverage'
        )
        @event_external_id = event_external_id
      end

      def call
        return                    if event.traded_live
        return update_event       if replay?
        return book_live_coverage if event.reload.bookable?

        log_job_message(
          :info,
          message: "'liveodd' for event is not '#{Event::BOOKABLE}'",
          event_id: event.external_id
        )
      end

      def update_event
        log_job_message(
          :debug,
          message: 'Updating traded live flag for event',
          event_id: event.external_id
        )

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
      rescue ActiveRecord::RecordNotFound => e
        log_job_message(:error, message: e.message, external_id: @event_external_id)
        raise e
      end

      def api_client
        @api_client ||= OddsFeed::Radar::Client.new
      end

      def replay?
        ENV['RADAR_MQ_LISTEN_ALL'] == 'true'
      end
    end
  end
end
