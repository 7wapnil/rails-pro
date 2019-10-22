# frozen_string_literal: true

module OddsFeed
  module Radar
    class EventStatusConverter < ApplicationService
      STATUSES_MAP = {
        0 => Event::NOT_STARTED,
        1 => Event::STARTED,
        2 => Event::SUSPENDED,
        3 => Event::ENDED,
        4 => Event::CLOSED,
        5 => Event::CANCELLED,
        6 => Event::DELAYED,
        7 => Event::INTERRUPTED,
        8 => Event::POSTPONED,
        9 => Event::ABANDONED
      }.stringify_keys

      BR_TEXT_STATUSES_MAP = {
        'not_started' => Event::NOT_STARTED,
        'live' => Event::STARTED,
        'suspended' => Event::SUSPENDED,
        'ended' => Event::ENDED,
        'closed' => Event::CLOSED,
        'cancelled' => Event::CANCELLED,
        'delayed' => Event::DELAYED,
        'interrupted' => Event::INTERRUPTED,
        'postponed' => Event::POSTPONED,
        'abandoned' => Event::ABANDONED
      }.freeze

      def initialize(status_input)
        @status_input = status_input
      end

      def call
        STATUSES_MAP[status_input] ||
          BR_TEXT_STATUSES_MAP[status_input] ||
          Event::NOT_STARTED
      end

      private

      attr_reader :status_input
    end
  end
end
