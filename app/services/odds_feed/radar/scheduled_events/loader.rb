# frozen_string_literal: true

module OddsFeed
  module Radar
    module ScheduledEvents
      class Loader < ApplicationService
        OFFSET_BETWEEN_BATCHES = 1.hour
        DEFAULT_RANGE = 3.days

        def initialize(from_date: Date.current, offset: DEFAULT_RANGE)
          @from_date = from_date.to_date
          @end_date = (from_date + offset).to_date
          @offset = offset
        end

        def call
          (from_date..end_date).each.with_index(&method(:load_events_for_date))
        end

        private

        attr_reader :from_date, :end_date, :offset

        def load_events_for_date(date, index)
          ::Radar::ScheduledEvents::DateEventsLoadingWorker.perform_in(
            index * OFFSET_BETWEEN_BATCHES,
            date.to_datetime.to_i
          )
        end
      end
    end
  end
end
