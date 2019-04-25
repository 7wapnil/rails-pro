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

      private

      def valid?
        return true if EventsManager::Entities::Event.type_match?(event_id)

        warning = "Event with external ID #{event_id} is not supported yet"
        log_process(:warn, warning)

        false
      end

      def update_event
        msg = "Updating event ID #{event_id}, change type '#{change_type}'"
        log_job_message(:info, msg)

        update_event_producer!
        update_event_payload!
      end

      def update_event_producer!
        return if producer == event.producer

        log_job_message(:info, "Updating producer for event ID #{event_id}")
        event.update(producer: producer)
      end

      def update_event_payload!
        log_job_message(:info, "Updating payload for event ID #{event_id}")

        event.update!(active: false) if change_type == :cancelled
      end

      def event_id
        payload['event_id']
      end

      def payload
        @payload['fixture_change']
      end

      def change_type
        CHANGE_TYPES[payload['change_type']]
      end

      def producer
        @producer ||= ::Radar::Producer.find(payload['product'])
      end

      def event
        @event ||= ::EventsManager::EventLoader.call(event_id)
      end
    end
  end
end
