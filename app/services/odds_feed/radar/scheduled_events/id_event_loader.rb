# frozen_string_literal: true

module OddsFeed
  module Radar
    module ScheduledEvents
      class IdEventLoader < ApplicationService
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
          log_job_message(
            :info,
            "Starting loading Event##{external_id}"
          )
        end

        def log_success
          log_job_message(
            :info,
            "Loaded Event##{external_id} successfully."
          )
        end

        def log_failure
          log_job_message(
            :error,
            "Failed to load Event##{external_id}."
          )
        end
      end
    end
  end
end
