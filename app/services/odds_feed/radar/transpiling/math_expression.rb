module OddsFeed
  module Radar
    module Transpiling
      class MathExpression < BaseExpression
        def value(token)
          parts = token.scan(/(.*)(\-|\+)(\d+)/)
          spec_number = specifier(parts[0][0]).to_i
          operand = parts[0][2].to_i
          parts[0][1] == '+' ? spec_number + operand : spec_number - operand
        end
      end
    end
  end
end
