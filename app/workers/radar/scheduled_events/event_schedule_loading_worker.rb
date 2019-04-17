# frozen_string_literal: true

module Radar
  module ScheduledEvents
    class EventScheduleLoadingWorker < ApplicationWorker
      sidekiq_options queue: 'radar_events_preloading'

      def perform
        OddsFeed::Radar::ScheduledEvents::EventScheduleLoader
          .call(timestamp: Time.zone.now)
      end
    end
  end
end
