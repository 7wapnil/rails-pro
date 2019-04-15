# frozen_string_literal: true

module OddsFeed
  module Radar
    module ScheduledEvents
      class Loader < ApplicationService
        DEFAULT_RANGE = 7.days

        def initialize(from_date: Date.current, offset: DEFAULT_RANGE)
          @from_date = from_date.to_date
          @end_date = (from_date + offset).to_date
        end

        def call
          (from_date..end_date).each(&method(:load_events_for_date))
        end

        private

        attr_reader :from_date, :end_date

        def load_events_for_date(date)
          ::Radar::ScheduledEvents::DateEventsLoadingWorker.perform_async(
            date.to_datetime.to_i
          )
        end
      end
    end
  end
end
