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
          competitors = event.payload['competitors']['competitor']
          unless competitors.blank?
            competitors.each.with_index do |competitor, i|
              vars["$competitor#{i + 1}"] = competitor['name']
            end
          end
          vars['$event'] = event.name

          vars
        end
      end
    end
  end
end
