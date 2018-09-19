module OddsFeed
  module Radar
    class FixtureChangeHandler < RadarMessageHandler
      CHANGE_TYPES = {
        '1' => :new,
        '2' => :datetime,
        '3' => :cancelled,
        '4' => :format,
        '5' => :coverage
      }.freeze

      def handle
        if event
          log_on_update
          event.update_from!(api_event)
        else
          log_on_create
          create_event!
        end
        update_event_payload!
      end

      private

      def event
        @event ||= Event.find_by(external_id: external_id)
      end

      def api_event
        @api_event ||= api_client.event(external_id).result
      end

      def payload
        @payload['fixture_change']
      end

      def external_id
        payload['event_id']
      end

      def create_event!
        @event = api_event
        event.save!
        ::Radar::LiveCoverageBookingWorker.perform_async(event.external_id)
      end

      def log_on_create
        Rails.logger.info("Creating event with external ID #{external_id}")
      end

      def log_on_update
        change_type = CHANGE_TYPES[payload['change_type']]
        msg = <<-MESSAGE
          Updating event with external ID #{external_id} \
          on change type '#{change_type}'
        MESSAGE

        Rails.logger.info(msg.squish)
      end

      def update_event_payload!
        msg = "Updating payload for event ID #{external_id}"
        Rails.logger.info msg

        event.add_to_payload(
          producer: { origin: :radar, id: payload['product'] }
        )

        event.save!
      end
    end
  end
end
