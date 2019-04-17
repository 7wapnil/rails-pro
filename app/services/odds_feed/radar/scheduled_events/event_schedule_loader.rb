# frozen_string_literal: true

module OddsFeed
  module Radar
    module ScheduledEvents
      class EventScheduleLoader < ApplicationService
        include JobLogger

        DEFAULT_RANGE = 7.days

        def initialize(timestamp:, range: DEFAULT_RANGE)
          @date_from = Time.at(timestamp).to_date
          @date_to = date_from + range
        end

        def call
          (date_from..date_to).each { |date| process date }
        end

        private

        attr_reader :date_from, :date_to

        def process(date)
          log_start date
          schedule_import date
          log_success date
        rescue StandardError => error
          log_failure date, error
        end

        def log_start(date)
          log_job_message(
            :info,
            "Event based data for #{humanize date} was received from response."
          )
        end

        def humanize(date)
          I18n.l(date, format: :informative)
        end

        def schedule_import(date)
          external_ids = events(date).map { |payload| payload[:external_id] }
          external_ids -= Event.where(external_id: external_ids)
                               .pluck(:external_id)
          external_ids.each do |external_id|
            ::Radar::ScheduledEvents::EventLoadingWorker
              .perform_async(external_id)
          end
        end

        def events(date)
          OddsFeed::Radar::Client
            .new
            .events_for_date(date)
            .map(&:result)
        end

        def log_success(date)
          log_job_message(
            :info,
            "Event based data caching for #{humanize date} was scheduled."
          )
        end

        def log_failure(date, error)
          log_job_message(
            :info,
            "Event based data for #{humanize date} was not cached."
          )

          log_job_message(:error, error.message)
        end
      end
    end
  end
end
