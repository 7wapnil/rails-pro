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

        log_job_message(
          :warn,
          message: I18n.t('errors.messages.unsupported_event_type'),
          event_id: event_id
        )

        false
      end

      def update_event
        log_job_message(:info, message: 'Updating event',
                               event_id: event_id,
                               change_type: change_type)

        update_event_producer!
        update_event_payload!
      end

      def update_event_producer!
        return if producer == event.producer

        log_job_message(:info, message: 'Updating producer',
                               event_id: event_id)

        ProducerUpdateService
          .call(event: event, producer_id: producer.id)
          .save
      rescue ActiveRecord::RecordNotFound => e
        log_job_message(
          :warn,
          message: I18n.t('errors.messages.nonexistent_producer'),
          id: e.id
        )
      end

      def update_event_payload!
        log_job_message(:info, message: 'Updating payload', event_id: event_id)

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
        @event ||= ::EventsManager::EventLoader.call(event_id, force: true)
      end
    end
  end
end
