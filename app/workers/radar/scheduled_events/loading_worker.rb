# frozen_string_literal: true

require 'sidekiq-scheduler'

module Radar
  module ScheduledEvents
    class LoadingWorker < ApplicationWorker
      sidekiq_options queue: 'scheduled_events_caching'

      def perform
        OddsFeed::Radar::ScheduledEvents::Loader.call
      end
    end
  end
end
