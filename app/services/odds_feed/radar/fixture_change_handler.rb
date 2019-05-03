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
        return preload_event_and_retry! unless event_exists?

        update_event
      end

      private

      def valid?
        type_valid? && (!producer.live? || producer.live? && event_exists?)
      end

      def type_valid?
        return true if EventsManager::Entities::Event.type_match?(event_id)

        log_job_failure(
          "Event with external ID #{event_id} could not be processed yet"
        )
        false
      end

      def event_id
        payload['event_id']
      end

      def payload
        @payload['fixture_change']
      end

      def producer
        @producer ||= ::Radar::Producer.find(payload['product'])
      end

      def event_exists?
        @event_exists ||= Event.exists?(external_id: event_id)
      end

      def preload_event_and_retry!
        ::Radar::ScheduledEvents::EventLoadingWorker.perform_async(event_id)

        log_job_failure(
          I18n.t('errors.messages.nonexistent_event', id: event_id)
        )

        raise SilentRetryJobError,
              I18n.t('errors.messages.nonexistent_event', id: event_id)
      end

      def update_event
        @event = load_event
        update_event_producer!
        update_event_payload!
      end

      def load_event
        log_on_update
        EventsManager::EventLoader.call(event_id, check_existence: false)
      end

      def log_on_update
        log_job_message(
          :info,
          message: "Updating event on change type '#{change_type}'",
          event_id: event_id
        )
      end

      def change_type
        CHANGE_TYPES[payload['change_type']]
      end

      def update_event_producer!
        return if producer == @event.producer

        log_job_message(
          :info,
          message: 'Updating producer for event',
          event_id: event_id
        )
        @event.update(producer: producer)
      end

      def update_event_payload!
        log_job_message(:info, message: 'Updating payload for event',
                               event_id: event_id)
        @event.active = false if change_type == :cancelled
        @event.save!
      end
    end
  end
end
