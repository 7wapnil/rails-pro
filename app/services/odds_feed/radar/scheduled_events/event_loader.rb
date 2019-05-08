# frozen_string_literal: true

module OddsFeed
  module Radar
    module ScheduledEvents
      class EventLoader < ApplicationService
        include JobLogger

        def initialize(external_id)
          @external_id = external_id
        end

        def call
          log_start
          EventsManager::EventLoader.call(external_id)
          log_success
        rescue StandardError => error
          log_failure
          raise(error)
        end

        private

        attr_reader :external_id

        def log_start
          log_job_message(:info, message: 'Start loading event',
                                 event_id: external_id)
        end

        def log_success
          log_job_message(:info, message: 'Event was loaded successfully',
                                 event_id: external_id)
        end

        def log_failure
          log_job_message(:error, message: 'Failed to load event',
                                  event_id: external_id)
        end
      end
    end
  end
end
