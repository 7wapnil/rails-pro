# frozen_string_literal: true

module OddsFeed
  module Radar
    module ScheduledEvents
      # rubocop:disable Metrics/ClassLength
      class DateEventsLoader < ApplicationService
        include JobLogger

        RECONNECTION_TIMEOUT = 15
        MAX_RETRIES = 5

        def initialize(timestamp:)
          @date = Time.at(timestamp).to_date
          @retries = 0
        end

        def call
          log_start
          collect_nested_associations
          import
          cache_data
          log_success
        rescue StandardError => error
          log_failure
          raise(error)
        end

        private

        attr_reader :date, :scoped_events, :retries

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

        def import
          import_events
          import_scoped_events
        end

        def import_events
          events.each do |event_payload|
            external_id = event_payload[:external_id]
            event = Event.find_by external_id: external_id
            next if event

            ::Radar::ScheduledEvents::IdEventLoadingWorker
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

        def cache_data
          cache_collection(collected_cache_data[:competitors])
          cache_collection(collected_cache_data[:players])
        rescue OpenSSL::SSL::SSLError => error
          increment_retries!
          log_connection_error

          raise error if retries > MAX_RETRIES

          sleep RECONNECTION_TIMEOUT
          retry
        end

        def collected_cache_data
          @collected_cache_data ||=
            events
            .reduce({}) { |data, event| collect_cache_data(data, event) }
        end

        def collect_cache_data(data, event)
          data.deep_merge(
            EventBasedCache::Collector.call(event: event)
          )
        end

        def cache_collection(cache_data)
          Rails.cache.write_multi(
            cache_data,
            cache: { expires_in: Entities::BaseLoader::CACHE_TERM }
          )
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

        def log_failure
          log_job_message(
            :fatal,
            "Event based data for #{humanized_date} was not cached."
          )
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
