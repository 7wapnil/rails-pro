# frozen_string_literal: true

module OddsFeed
  module Radar
    module ScheduledEvents
      # rubocop:disable Metrics/ClassLength
      class EventScheduleLoader < ApplicationService
        include JobLogger

        RECONNECTION_TIMEOUT = 15
        MAX_RETRIES = 5
        DEFAULT_RANGE = 7.days

        def initialize(timestamp:, range: DEFAULT_RANGE)
          @date_from = Time.at(timestamp).to_date
          @date_to = date_from + range
          @retries = 0
        end

        def call
          (date_from..date_to).each { |day| process day }
        end

        private

        attr_reader :date, :date_from, :date_to, :scoped_events, :retries

        def process(schedule_date)
          @date = schedule_date
          log_start
          collect_nested_associations
          schedule_import
          log_success
        rescue StandardError => error
          log_failure(error)
        end

        def log_start
          log_job_message(
            :info,
            "Event based data for #{humanized_date} was received from response."
          )
        end

        def humanized_date
          I18n.l(date, format: :informative)
        end

        def collect_nested_associations
          @scoped_events = events.flat_map(&:scoped_events)
        end

        def schedule_import
          import_events
          import_scoped_events
        end

        def import_events
          events.each do |event_payload|
            external_id = event_payload[:external_id]
            event = Event.find_by external_id: external_id
            next if event

            ::Radar::ScheduledEvents::EventLoadingWorker
              .perform_async(external_id)
          end
        end

        def import_scoped_events
          ScopedEvent.import(
            scoped_events,
            validate: false,
            on_duplicate_key_update: {
              conflict_target: %i[event_id event_scope_id],
              columns: %i[updated_at]
            }
          )
        end

        def events
          @events ||= OddsFeed::Radar::Client
                      .new
                      .events_for_date(date)
                      .map(&:result)
        end

        def log_connection_error
          log_job_message(
            :info,
            "Event based data for #{humanized_date} has met connection " \
            "error. Retrying(#{retries})..."
          )
        end

        def increment_retries!
          @retries += 1
        end

        def log_success
          log_job_message(
            :info,
            "Event based data caching for #{humanized_date} was scheduled."
          )
        end

        def log_failure(error)
          log_job_message(
            :info,
            "Event based data for #{humanized_date} was not cached."
          )

          log_job_message(:error, error.message)
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
