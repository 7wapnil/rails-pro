# frozen_string_literal: true

require 'sidekiq-scheduler'

module Radar
  module ScheduledEvents
    class LoadingWorker < ApplicationWorker
      sidekiq_options queue: 'radar_events_preloading'

      def perform
        OddsFeed::Radar::ScheduledEvents::Loader.call
      end
    end
  end
end
