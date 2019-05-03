# frozen_string_literal: true

module OddsFeed
  module Radar
    # rubocop:disable Metrics/ClassLength
    class OddsChangeHandler < RadarMessageHandler
      def handle
        validate!

        update_event!
        update_odds
        emit_websocket

        event
      end

      private

      def validate!
        validate_payload!
        validate_type!
      end

      def validate_payload!
        payload_err = "Odds change payload is malformed: #{@payload}"
        raise OddsFeed::InvalidMessageError, payload_err unless input_data
      end

      def validate_type!
        is_valid = EventsManager::Entities::Event.type_match?(event_id)
        type_err = "Event type with external ID #{event_id} is not supported"
        raise OddsFeed::InvalidMessageError, type_err unless is_valid
      end

      def event_id
        input_data['event_id']
      end

      def event
        @event ||= Event
                   .includes(:competitors, :players, :event_scopes, :title)
                   .find_by!(external_id: event_id)
      rescue ActiveRecord::RecordNotFound
        ::Radar::ScheduledEvents::EventLoadingWorker.perform_async(event_id)

        log_job_failure(
          I18n.t('errors.messages.nonexistent_event', id: event_id)
        )

        raise SilentRetryJobError,
              I18n.t('errors.messages.nonexistent_event', id: event_id)
      end

      def update_event!
        update_event_payload
        update_event_attributes
        event.save!
      end

      def update_event_payload
        new_state = OddsFeed::Radar::EventStatusService.new.call(
          event_id: event.id, data: event_status_payload
        )
        event.add_to_payload(state: new_state)
      end

      def update_event_attributes
        updates = { remote_updated_at: timestamp,
                    status: event_status,
                    end_at: event_end_time,
                    active: event_active?,
                    producer: ::Radar::Producer.find(input_data['product']) }

        event.assign_attributes(updates)
        log_updates!(updates)
      end

      def event_active?
        status_positive? && active_odds?
      end

      def active_odds?
        Odd
          .joins(:market)
          .where('odds.status': Odd::ACTIVE,
                 'markets.event_id': event.id,
                 'markets.status': [Market::ACTIVE,
                                    Market::SUSPENDED])
          .count
          .positive?
      end

      def status_positive?
        [Event::ENDED,
         Event::CLOSED,
         Event::CANCELLED,
         Event::ABANDONED].exclude?(event_status)
      end

      def fetch_outcomes_data(data)
        return data if data.is_a?(Array)

        return [data] if data.is_a?(Hash)

        []
      end

      def log_updates!(updates)
        log_job_message(
          :info,
          message: 'Updating event',
          event_id: event_id,
          product_id: input_data['product'],
          attributes: updates
        )
      end

      def update_odds
        return if markets_data.empty?

        ::OddsFeed::Radar::MarketGenerator::Service
          .call(event, markets_data)
      end

      def markets_data
        @markets_data ||= Array[fetch_markets_data].compact.flatten
      end

      def fetch_markets_data
        return markets_payload if markets_payload.is_a?(Enumerable)

        log_missing_payload if odds_payload.is_a?(Hash)

        []
      end

      def markets_payload
        @markets_payload ||= odds_payload.to_h['market']
      end

      def odds_payload
        @odds_payload ||= input_data['odds']
      end

      def input_data
        @payload['odds_change']
      end

      def event_status
        raise KeyError unless event_status_payload

        status = event_status_payload.fetch('status')
        event_statuses_map[status] || Event::NOT_STARTED
      rescue KeyError
        log_job_message(
          :warn,
          message: 'Event status missing in payload for Event',
          event_id: event_id
        )
        Event::NOT_STARTED
      end

      def event_status_payload
        input_data['sport_event_status']
      end

      def event_end_time
        return nil unless event_status == Event::ENDED

        timestamp
      end

      def event_statuses_map
        {
          0 => Event::NOT_STARTED,
          1 => Event::STARTED,
          2 => Event::SUSPENDED,
          3 => Event::ENDED,
          4 => Event::CLOSED,
          5 => Event::CANCELLED,
          6 => Event::DELAYED,
          7 => Event::INTERRUPTED,
          8 => Event::POSTPONED,
          9 => Event::ABANDONED
        }.stringify_keys
      end

      def timestamp
        Time.at(input_data['timestamp'].to_i / 1000).utc
      end

      def emit_websocket
        WebSocket::Client.instance.trigger_event_update(event)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
