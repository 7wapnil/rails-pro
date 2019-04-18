# frozen_string_literal: true

module Radar
  module ScheduledEvents
    class EventLoadingWorker < ApplicationWorker
      sidekiq_options queue: 'scheduled_events_caching',
                      lock: :until_and_while_executing,
                      on_conflict: :log,
                      unique_args: ->(args) { [args.first] }

      def perform(external_id)
        OddsFeed::Radar::ScheduledEvents::EventLoader
          .call(external_id)
      end
    end
  end
end
