module OddsFeed
  module Radar
    class OddsChangeHandler < RadarMessageHandler
      def handle
        event = create_or_update_event!
        event_data['odds']['market'].each do |market_data|
          generate_market!(event, market_data)
        end
      end

      private

      def event_data
        @payload['odds_change']
      end

      def timestamp
        Time.at(event_data['@timestamp'].to_i / 1000).utc
      end

      def create_or_update_event!
        id = event_data['@event_id']
        event = Event.find_by(external_id: id)
        if event.nil?
          event = create_event(id)
        else
          check_message_time(event)
        end
        event.update_attribute(:updated_at, timestamp)
        event
      end

      def create_event(external_id)
        event = request_event(external_id)
        event.save!
        event.title&.save!
        if event.event_scopes.any?
          event.event_scopes.each { |scope| scope&.save! }
        end
        event
      end

      def request_event(id)
        api_client.event(id).result
      end

      def check_message_time(event)
        last_update = event.updated_at.utc
        msg = "Message came at #{timestamp}, but last update was #{last_update}"
        raise InvalidMessageError, msg if event.updated_at.utc > timestamp
      end

      def generate_market!(event, market_data)
        MarketGenerator.new(event, market_data).generate
      end
    end
  end
end
