# frozen_string_literal: true

module OddsFeed
  module Radar
    module EventCreatable
      extend ActiveSupport::Concern

      included do
        protected

        attr_reader :event, :event_id

        def create_event
          @event = api_event

          collect_possible_duplicates
          Event.create_or_update_on_duplicate(event)
          handle_duplicates
          cache_event_based_data
        end

        def api_event
          @api_event ||= api_client.event(event_id).result
        end

        def valid_event_type?
          event_id.to_s.match?(EventAdapter::MATCH_TYPE_REGEXP)
        end

        def invalid_event_type
          log_job_failure(
            "Event with external ID #{event_id} could not be processed yet"
          )
          nil
        end

        def cache_event_based_data
          EventBasedCache::Writer.call(event: event)
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
            Event #{event_id} has duplicated EventScope \
            #{scoped_event.event_scope.external_id}
          MESSAGE

          log_job_message(:warn, message.squish)
        end
      end
    end
  end
end
