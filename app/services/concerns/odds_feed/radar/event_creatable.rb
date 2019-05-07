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
          log_job_message(:error, message: 'Event cannot be processed yet',
                                  event_id: event_id)
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
          message = 'Event has duplicated EventScope'
          scope_id = scoped_event.event_scope.external_id

          log_job_message(:warn, message: message,
                                 event_id: event_id,
                                 scope_external_id: scope_id)
        end
      end
    end
  end
end
