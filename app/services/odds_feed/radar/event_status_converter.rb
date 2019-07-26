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

      def initialize(status_number)
        @status_number = status_number
      end

      def call
        STATUSES_MAP[@status_number] || Event::NOT_STARTED
      end
    end
  end
end
