module OddsFeed
  module Radar
    module Transpiling
      class SignedExpression < BaseExpression
        def value(token)
          number = specifier(token[1..-1])
          token_sign = token[0]
          number_sign = number[0]

          return "#{token_sign}#{number}" unless %w[+ -].member?(number_sign)
          return "-#{number[1..-1]}" if token_sign != number_sign

          "+#{number[1..-1]}"
        end
      end
    end
  end
end
