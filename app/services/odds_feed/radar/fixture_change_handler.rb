# frozen_string_literal: true

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
        return unless valid?

        update_event
      end

      def update_event
        event = load_event
        update_event_producer!(event, producer)
        update_event_payload!(event)
      end

      private

      def valid?
        return false unless type_valid?
        return false if event_exists? == false && producer.live?

        true
      end

      def type_valid?
        return true if EventsManager::Entities::Event.type_match?(event_id)

        log_job_failure(
          "Event with external ID #{event_id} could not be processed yet"
        )
        false
      end

      def load_event
        event = EventsManager::EventLoader.call(event_id,
                                                check_existence: false)
        log_on_update
        event
      end

      def event_exists?
        Event.exists?(external_id: event_id)
      end

      def event_id
        payload['event_id']
      end

      def payload
        @payload['fixture_change']
      end

      def producer
        ::Radar::Producer.find(payload['product'])
      end

      def log_on_update
        msg = <<-MESSAGE
          Updating event with external ID #{event_id} \
          on change type '#{change_type}'
        MESSAGE

        log_job_message(:info, msg.squish)
      end

      def change_type
        CHANGE_TYPES[payload['change_type']]
      end

      def update_event_producer!(event, new_producer)
        return if new_producer == event.producer

        log_job_message(:info, "Updating producer for event ID #{event_id}")
        event.update(producer: new_producer)
      end

      def update_event_payload!(event)
        log_job_message(:info, "Updating payload for event ID #{event_id}")

        event.active = false if change_type == :cancelled

        event.save!
      end
    end
  end
end
