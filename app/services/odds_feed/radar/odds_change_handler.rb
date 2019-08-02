# frozen_string_literal: true

module OddsFeed
  module Radar
    # rubocop:disable Metrics/ClassLength
    class OddsChangeHandler < RadarMessageHandler
      def handle
        validate_payload!
        return unless valid?

        update_event!
        update_odds
        emit_websocket

        event
      end

      private

      def validate_payload!
        payload_err = "Odds change payload is malformed: #{@payload}"
        raise OddsFeed::InvalidMessageError, payload_err unless input_data
      end

      def valid?
        valid_type? && event_ready?
      end

      def valid_type?
        return true if EventsManager::Entities::Event.type_match?(event_id)

        log_job_message(
          :warn,
          message: I18n.t('errors.messages.unsupported_event_type'),
          event_id: event_id
        )

        false
      end

      def event_ready?
        return true if event.ready?

        log_job_message(
          :info,
          message: 'Event is not yet ready to be processed',
          event_id: event_id
        )

        false
      end

      def event_id
        input_data['event_id']
      end

      def event
        @event ||= ::EventsManager::EventLoader.call(event_id,
                                                     includes: %i[competitors
                                                                  players
                                                                  event_scopes
                                                                  title])
      end

      def update_event!
        update_event_attributes
        update_producer
        event.save!
      end

      def update_event_attributes
        updates = {
          remote_updated_at: timestamp,
          status: event_status,
          end_at: event_end_time,
          active: event_active?,
          display_status: event_display_status,
          home_score: event_home_score,
          away_score: event_away_score,
          time_in_seconds: event_time_in_seconds
        }

        event.assign_attributes(updates)
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

        @event_status ||=
          EventStatusConverter.call(event_status_payload.fetch('status'))
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

      def event_display_status
        MatchStatusMappingService.new.call(
          event_status_payload.fetch('match_status')
        )
      end

      def event_home_score
        event_status_payload['home_score']&.to_i
      end

      def event_away_score
        event_status_payload['away_score']&.to_i
      end

      def event_time_in_seconds
        match_time = event_status_payload.dig('clock', 'match_time')

        return unless match_time

        minutes = match_time.to_i
        seconds = match_time.split(':').second.to_i
        (minutes.minutes + seconds.seconds).to_i
      end

      def update_producer
        ProducerUpdateService.call(
          event: event,
          producer_id: ::Radar::Producer.find(input_data['product']).id
        )
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
