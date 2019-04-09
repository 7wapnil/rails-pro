module OddsFeed
  module Radar
    module Transpiling
      class VariableExpression < BaseExpression
        def value(token)
          variables[token] || ''
        end

        private

        def variables
          vars = {}
          vars['$event'] = event.name
          event.competitors.each.with_index do |competitor, i|
            vars["$competitor#{i + 1}"] = competitor['name']
          end

          vars
        end
      end
    end
  end
end
