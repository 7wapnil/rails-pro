# frozen_string_literal: true

module OddsFeed
  module Radar
    module Timestampable
      TIMESTAMP_FORMAT = '%Q'

      protected

      def parse_timestamp(timestamp)
        Time.zone.strptime(timestamp, TIMESTAMP_FORMAT)
      end
    end
  end
end
