module OddsFeed
  module Radar
    # rubocop:disable Metrics/ClassLength
    class OddsChangeHandler < RadarMessageHandler
      def handle
        create_or_update_event!
        touch_event!
        generate_markets
        update_event_activity
        emit_websocket
        event
      end

      private

      def create_or_update_event!
        if event
          check_message_time
        else
          msg = <<-MESSAGE
            Event with external ID #{external_id} \
            not found, creating new
          MESSAGE

          log_job_message(:info, msg.squish)

          create_or_find_event!
        end
      end

      def touch_event!
        event.producer = ::Radar::Producer.find(event_data['product'])
        new_state = OddsFeed::Radar::EventStatusService.new.call(
          event_id: event.id, data: event_data['sport_event_status']
        )
        event.add_to_payload(state: new_state)
        process_updates!
        event.save!
        event.emit_state_updated
      end

      def process_updates!
        updates = { remote_updated_at: timestamp,
                    status: event_status,
                    end_at: event_end_time }
        log_updates!(updates)
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

      def log_updates!(updates)
        msg = <<-MESSAGE
            Updating event with ID #{external_id}, \
            product ID #{event_data['product']}, attributes #{updates}
        MESSAGE
        log_job_message(:info, msg)
      end

      def generate_markets
        return if markets_data.empty?

        call_markets_generator
      end

      def update_event_activity
        event.update_attributes!(active: event_active?)
      end

      def call_markets_generator
        ::OddsFeed::Radar::MarketGenerator::Service.call(event.id, markets_data)
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
        @odds_payload ||= event_data['odds']
      end

      def log_missing_payload
        log_job_message(
          :info, "Odds payload is missing for Event #{external_id}"
        )
      end

      def event_data
        @payload['odds_change']
      rescue StandardError => e
        log_job_message(:debug, { error: e, payload: @payload }.to_json)
      end

      def event_status
        status = event_data['sport_event_status']['status']
        event_statuses_map[status] || Event::NOT_STARTED
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

      def event
        @event ||= Event.find_by(external_id: external_id)
      end

      def api_event
        @api_event ||= api_client.event(external_id).result
      end

      def timestamp
        Time.at(event_data['timestamp'].to_i / 1000).utc
      end

      def external_id
        event_data['event_id']
      end

      def create_or_find_event!
        @event = api_event
        begin
          Event.create_or_update_on_duplicate(event)

          return if event.bookable?

          ::Radar::LiveCoverageBookingWorker.perform_async(external_id)
        rescue StandardError => e
          log_job_message(
            :warn, ["Event ID #{external_id} creating failed", e.message]
          )
        end
      end

      def check_message_time
        return unless event.remote_updated_at

        last_update = event.remote_updated_at.utc
        return if event.remote_updated_at.utc <= timestamp

        msg = "Message came at #{timestamp}, but last update was #{last_update}"
        log_job_message(:warn, msg)
      end

      def emit_websocket
        WebSocket::Client.instance.emit(WebSocket::Signals::EVENT_UPDATED,
                                        id: event.id.to_s)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
