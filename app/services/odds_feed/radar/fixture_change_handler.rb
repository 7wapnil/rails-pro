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

        log_job_message(:warn, message: 'Event is not supported yet',
                               event: event_id)

        false
      end

      def update_event
        log_job_message(:info, message: 'Updating event',
                               change_type: change_type)

        update_event_producer!
        update_event_payload!
      end

      def update_event_producer!
        return if producer == event.producer

        log_job_message(:info, message: 'Updating producer for event',
                               event_id: event_id)
        event.update(producer: producer)
      rescue ActiveRecord::RecordNotFound => e
        log_job_message(
          :warn,
          message: I18n.t('errors.messages.nonexistent_producer'),
          id: e.id
        )
      end

      def update_event_payload!
        log_job_message(:info, message: 'Updating payload for event',
                               event_id: event_id)

        event.update!(active: false) if change_type == :cancelled
      end

      def change_type
        CHANGE_TYPES[payload['change_type']]
      end
    end
  end
end
