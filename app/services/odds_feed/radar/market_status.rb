module OddsFeed
  module Radar
    class MarketStatus
      MARKET_STATUS_MAP = {
        1  => ACTIVE      = :active,
        0  => INACTIVE    = :inactive,
        -1 => SUSPENDED   = :suspended,
        -2 => HANDED_OVER = :handed_over,
        -3 => SETTLED     = :settled,
        -4 => CANCELED    = :canceled
      }.freeze

      attr_reader :id

      def self.code(status)
        MARKET_STATUS_MAP.key(status)
      end

      def initialize(id)
        @id = id&.to_i
      end

      def empty?
        id.nil?
      end

      def status
        MARKET_STATUS_MAP[id] if id
      end
    end
  end
end
