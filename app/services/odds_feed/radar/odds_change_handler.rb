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
        msg = "Updating timestamp and payload for event ID #{external_id}"
        Rails.logger.info msg

        event.add_to_payload(
          producer: { origin: :radar, id: event_data['product'] }
        )

        event.assign_attributes(remote_updated_at: timestamp)
        event.save!
      end

      def generate_markets
        event_data['odds']['market'].each do |market_data|
          generate_market!(event, market_data)
        rescue StandardError => e
          Rails.logger.error e
          next
        end
      end

      def event_data
        @payload['odds_change']
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
        WebSocket::Client.instance.emit(WebSocket::Signals::UPDATE_EVENT,
                                        id: event.id.to_s,
                                        name: event.name,
                                        start_at: event.start_at)
      end

      def check_message_time
        return unless event.remote_updated_at

        last_update = event.remote_updated_at.utc
        return if event.remote_updated_at.utc <= timestamp

        msg = "Message came at #{timestamp}, but last update was #{last_update}"
        raise InvalidMessageError, msg
      end

      def generate_market!(event, market_data)
        Rails.logger.info "Generating market for event #{event.external_id}"
        MarketGenerator.new(event, market_data).generate
      end
    end
  end
end
