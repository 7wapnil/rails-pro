module OddsFeed
  module Radar
    module EventCreatable
      extend ActiveSupport::Concern

      included do
        def api_client
          raise NotImplementedError, 'Method #api_client has to be implemented'
        end

        protected

        attr_reader :event

        def create_event
          @event = api_event

          collect_possible_duplicates
          Event.create_or_update_on_duplicate(event)
          handle_duplicates

          return if event.bookable?

          ::Radar::LiveCoverageBookingWorker.perform_async(event.external_id)
        end

        def api_event
          @api_event ||= api_client.event(external_id).result
        end

        private

        def collect_possible_duplicates
          @scoped_events = event.scoped_events.delete(event.scoped_events)
        end

        def handle_duplicates
          @scoped_events.each(&method(:handle_scoped_event))
        end

        def handle_scoped_event(scoped_event)
          scoped_event.update!(event_id: event.id)
        rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
          message = <<-MESSAGE
            Event #{external_id} has duplicated EventScope \
            #{scoped_event.event_scope.external_id}
          MESSAGE

          log_job_message(:warn, message.squish)
        end
      end
    end
  end
end
