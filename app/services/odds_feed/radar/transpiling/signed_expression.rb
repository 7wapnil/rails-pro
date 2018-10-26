module OddsFeed
  module Radar
    module Transpiling
      class SignedExpression < BaseExpression
        def value(token)
          sign = token[0]
          number = specifier(token[1..-1])
          "#{sign}#{number}"
        end
      end
    end
  end
end
