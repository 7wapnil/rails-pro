module Mts
  class MtsDecimal
    MAX_ALLOWED_PRECISION = 5
    MAX_VALUE = 1_000_000_000_000_000_000
    MIN_VALUE = 1

    def self.from_number(number)
      mts_value = (number.to_d * 10_000).round
      raise ArgumentError unless (MIN_VALUE..MAX_VALUE).cover? mts_value

      mts_value
    end
  end
end
