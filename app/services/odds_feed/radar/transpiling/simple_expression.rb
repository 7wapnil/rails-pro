module OddsFeed
  module Radar
    module Transpiling
      class SimpleExpression < BaseExpression
        def value(token)
          specifiers_map[token] || ''
        end
      end
    end
  end
end
