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
        update_event_producer!(::Radar::Producer.find(payload['product']))
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
        Event.create_or_update_on_duplicate(@event)
        ::Radar::LiveCoverageBookingWorker.perform_async(event.external_id)
      end

      def log_on_create
        log_job_message(:info, "Creating event with external ID #{external_id}")
      end

      def change_type
        CHANGE_TYPES[payload['change_type']]
      end

      def log_on_update
        msg = <<-MESSAGE
          Updating event with external ID #{external_id} \
          on change type '#{change_type}'
        MESSAGE

        log_job_message(:info, msg.squish)
      end

      def update_event_producer!(new_producer)
        return if new_producer == event.producer

        log_job_message(:info, "Updating producer for event ID #{external_id}")
        event.update(producer: new_producer)
      end

      def update_event_payload!
        log_job_message(:info, "Updating payload for event ID #{external_id}")

        event.active = false if change_type == :cancelled

        event.save!
      end
    end
  end
end
