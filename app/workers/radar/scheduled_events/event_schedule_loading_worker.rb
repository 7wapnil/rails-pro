# frozen_string_literal: true

module Radar
  module ScheduledEvents
    class EventScheduleLoadingWorker < ApplicationWorker
      sidekiq_options queue: 'scheduled_events_caching'

      def perform
        OddsFeed::Radar::ScheduledEvents::EventScheduleLoader
          .call(timestamp: Time.zone.now)
      end
    end
  end
end
