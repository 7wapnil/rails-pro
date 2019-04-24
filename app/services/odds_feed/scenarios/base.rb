# frozen_string_literal: true

module OddsFeed
  module Scenarios
    class Base < ApplicationService
      def call
        event_ids.each { |event_id| load_event(event_id) }
      end

      protected

      def event_ids
        raise NotImplementedError, 'Method #event_ids has to be implemented!'
      end

      private

      def load_event(event_id)
        ::Radar::ScheduledEvents::EventLoadingWorker.perform_async(event_id)
      end
    end
  end
end
