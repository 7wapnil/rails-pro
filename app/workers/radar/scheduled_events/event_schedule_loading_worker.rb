# frozen_string_literal: true

module Radar
  module ScheduledEvents
    class EventScheduleLoadingWorker < ApplicationWorker
      sidekiq_options queue: 'scheduled_events_caching'

      def perform(timestamp)
        OddsFeed::Radar::ScheduledEvents::EventScheduleLoader
          .call(timestamp: timestamp)
      end
    end
  end
end
