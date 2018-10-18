module OddsFeed
  module Radar
    class OddsChangeHandler < RadarMessageHandler
      def handle
        ActiveRecord::Base.transaction do
          create_or_update_event!
          touch_event!
        end
        generate_markets
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

          Rails.logger.info msg.squish

          create_event!
        end
      end

      def touch_event!
        event.add_to_payload(
          producer: { origin: :radar, id: event_data['product'] }
        )

        updates = { remote_updated_at: timestamp,
                    status: event_status,
                    end_at: event_end_time }

        msg = <<-MESSAGE
            Updating event with ID #{external_id}, \
            product ID #{event_data['product']}, attributes #{updates}
        MESSAGE
        Rails.logger.info msg
        event.assign_attributes(updates)
        event.save!
      end

      def markets_data
        data = event_data['odds']['market']
        data.is_a?(Array) ? data : [data]
      rescue StandardError => e
        Rails.logger.debug({ error: e, payload: @payload }.to_json)
      end

      def generate_markets
        markets_data.each do |market_data|
          generate_market!(event, market_data)
        rescue StandardError => e
          Rails.logger.error e
          Rails.logger.debug({ error: e, payload: @payload }.to_json)
          next
        end
      end

      def event_data
        @payload['odds_change']
      rescue StandardError => e
        Rails.logger.debug({ error: e, payload: @payload }.to_json)
      end

      def event_status
        status = event_data['sport_event_status']['status'] ||
                 Event.statuses[:not_started]
        event_statuses_map[status]
      end

      def event_end_time
        return nil unless event_status == Event.statuses[:ended]

        timestamp
      end

      def event_statuses_map
        {
          '0': Event.statuses[:not_started],
          '1': Event.statuses[:started],
          '3': Event.statuses[:ended],
          '4': Event.statuses[:closed]
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

      def create_event!
        @event = api_event
        event.save!
        ::Radar::LiveCoverageBookingWorker.perform_async(event.external_id)
      end

      def check_message_time
        return unless event.remote_updated_at

        last_update = event.remote_updated_at.utc
        return if event.remote_updated_at.utc <= timestamp

        msg = "Message came at #{timestamp}, but last update was #{last_update}"
        raise InvalidMessageError, msg
      end

      def generate_market!(event, market_data)
        Rails.logger.debug "Generating market for event #{event.external_id}"
        MarketGenerator.new(event, market_data).generate
      end
    end
  end
end
