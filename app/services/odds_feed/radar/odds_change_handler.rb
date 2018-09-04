module OddsFeed
  module Radar
    class OddsChangeHandler < RadarMessageHandler
      def handle
        ActiveRecord::Base.transaction do
          handle_message
        end
      end

      private

      def handle_message
        event = create_or_update_event!
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

      def timestamp
        Time.at(event_data['timestamp'].to_i / 1000).utc
      end

      def create_or_update_event!
        id = event_data['event_id']
        event = Event.find_by(external_id: id)
        if event.nil?
          Rails.logger.info "Event with external ID #{id} not found, create new"
          event = create_event(id)
        else
          check_message_time(event)
        end
        Rails.logger.info "Update timestamp for event ID #{id}"
        event.assign_attributes(remote_updated_at: timestamp)
        event.save!
        event
      end

      def create_event(external_id)
        event = request_event(external_id)
        event.save!
        WebSocket::Client.instance.emit(WebSocket::Signals::UPDATE_EVENT,
                                        id: event.id.to_s,
                                        name: event.name,
                                        start_at: event.start_at)
        event
      end

      def request_event(id)
        api_client.event(id).result
      end

      def check_message_time(event)
        last_update = event.remote_updated_at.utc
        msg = "Message came at #{timestamp}, but last update was #{last_update}"
        if event.remote_updated_at.utc > timestamp
          raise InvalidMessageError, msg
        end
      end

      def generate_market!(event, market_data)
        MarketGenerator.new(event, market_data).generate
      end
    end
  end
end
