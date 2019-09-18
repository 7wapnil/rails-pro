# frozen_string_literal: true

module OddsFeed
  module Radar
    module Timestampable
      protected

      def parse_timestamp(timestamp)
        Time.at(timestamp[0..-4].to_i).to_datetime
      end
    end
  end
end
