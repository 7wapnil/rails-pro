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
          event
            .competitors
            .joins(:event_competitor)
            .order('event_competitors.id ASC')
            .each.with_index do |competitor, i|
              vars["$competitor#{i + 1}"] = competitor['name']
            end

          vars
        end
      end
    end
  end
end
