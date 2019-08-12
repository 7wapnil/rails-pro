module OddsFeed
  module Radar
    module Transpiling
      class SignedExpression < BaseExpression
        def value(token)
          sign = token[0]
          number = specifier(token[1..-1])

          return "#{sign}#{number}" unless number[0] == '-' || number[0] == '+'
          return "-#{number[1..-1]}" if sign != number[0]

          "+#{number[1..-1]}"
        end
      end
    end
  end
end
