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
        if event
          log_on_update
          event.update_from!(api_event)
        else
          log_on_create
          @event = api_event
          event.save!
        end

        notify_websocket
      end

      private

      def event
        @event ||= Event.find_by(external_id: payload['event_id'])
      end

      def api_event
        @api_event ||= api_client.event(payload['event_id']).result
      end

      def payload
        @payload['fixture_change']
      end

      def log_on_create
        event_id = payload['event_id']
        Rails.logger.info("Creating event with external ID #{event_id}")
      end

      def log_on_update
        event_id = payload['event_id']
        change_type = CHANGE_TYPES[payload['change_type']]
        msg = <<-MESSAGE
          Updating event with external ID #{event_id} \
          on change type '#{change_type}'
        MESSAGE

        Rails.logger.info(msg.squish)
      end

      def notify_websocket
        WebSocket::Client.instance.emit(
          WebSocket::Signals::UPDATE_EVENT,
          id: event.id.to_s,
          name: event.name,
          start_at: event.start_at
        )
      end
    end
  end
end
