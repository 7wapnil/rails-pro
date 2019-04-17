# frozen_string_literal: true

module Radar
  module ScheduledEvents
    class EventLoadingWorker < ApplicationWorker
      sidekiq_options queue: 'scheduled_events_caching'

      def perform(external_id)
        OddsFeed::Radar::ScheduledEvents::EventLoader
          .call(external_id)
      end
    end
  end
end
