# frozen_string_literal: true

module OddsFeed
  module Scenarios
    class Base < ApplicationService
      def call
        event_ids.each { |event_id| load_event(event_id) }
      end

      def event_ids
        @event_ids ||= CSV
                       .parse(File.read(scenario_path), headers: false)
                       .flatten
      end

      protected

      def scenario_path
        raise NotImplementedError, 'Define #scenario_path!'
      end

      private

      def load_event(event_id)
        ::Radar::ScheduledEvents::EventLoadingWorker.perform_async(event_id)
      end
    end
  end
end
