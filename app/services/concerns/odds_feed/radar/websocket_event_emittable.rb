module OddsFeed
  module Radar
    module WebsocketEventEmittable
      extend ActiveSupport::Concern

      included do
        private

        def event_id
          input_data['event_id']
        end

        def event
          @event ||= Event.find_by(external_id: event_id)
        end

        def emit_websocket
          unless event
            return log_job_message(
              :warn,
              message: 'Event not found',
              event_id: event_id
            )
          end

          WebSocket::Client.instance.trigger_event_update(event)
        end
      end
    end
  end
end
