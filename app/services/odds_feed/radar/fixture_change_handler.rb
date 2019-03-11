# frozen_string_literal: true

module OddsFeed
  module Radar
    class FixtureChangeHandler < RadarMessageHandler
      include EventCreatable

      CHANGE_TYPES = {
        '1' => :new,
        '2' => :datetime,
        '3' => :cancelled,
        '4' => :format,
        '5' => :coverage
      }.freeze

      def handle
        return invalid_event_type unless valid_event_type?
        return if event.blank? && producer.live?

        if event
          log_on_update
          event.update_from!(api_event)
          cache_event_competitors
        else
          log_on_create
          create_event
        end
        update_event_producer!(producer)
        update_event_payload!
      end

      private

      def event
        @event ||= Event.find_by(external_id: event_id)
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

      def log_on_create
        log_job_message(:info, "Creating event with external ID #{event_id}")
      end

      def update_event_producer!(new_producer)
        return if new_producer == event.producer

        log_job_message(:info, "Updating producer for event ID #{event_id}")
        event.update(producer: new_producer)
      end

      def update_event_payload!
        log_job_message(:info, "Updating payload for event ID #{event_id}")

        event.active = false if change_type == :cancelled

        event.save!
      end
    end
  end
end
