module OddsFeed
  module Radar
    class MarketStatus
      MARKET_STATUS_MAP = {
        1 => ACTIVE = :active,
        0 => INACTIVE = :inactive,
        -1 => SUSPENDED = :suspended,
        -2 => HANDED_OVER = :handed_over,
        -3 => SETTLED = :settled,
        -4 => CANCELLED = :cancelled
      }.freeze

      MARKET_MODEL_STATUS_MAP = {
        INACTIVE => Market::INACTIVE,
        ACTIVE => Market::ACTIVE,
        SUSPENDED => Market::SUSPENDED,
        CANCELLED => Market::CANCELLED,
        SETTLED => Market::SETTLED,
        HANDED_OVER => Market::HANDED_OVER
      }.freeze

      UNEXPECTED_CODE_MSG = 'unexpected market_status code'.freeze

      attr_reader :code

      def self.stop_status(code)
        new(code).market_status || SUSPENDED
      end

      def initialize(code)
        @code = code&.to_i
        validate_code!(@code)
      end

      def market_status
        MARKET_MODEL_STATUS_MAP[status]
      end

      private

      def validate_code!(code)
        invalid_code_exception unless allowed_codes.include?(code)
      end

      def invalid_code_exception
        raise ArgumentError, UNEXPECTED_CODE_MSG
      end

      def allowed_codes
        MARKET_STATUS_MAP.keys + [nil]
      end

      def status
        MARKET_STATUS_MAP[code] if code
      end
    end
  end
end
