module OddsFeed
  module Radar
    module Transpiling
      class VariableExpression < BaseExpression
        def value(token)
          variables[token] || ''
        end

        private

        def variables
          {
            '$event'       => event.name,
            '$competitor1' => competitors[EventCompetitor::HOME],
            '$competitor2' => competitors[EventCompetitor::AWAY]
          }
        end

        def competitors
          @competitors ||= ordered_competitors
        end

        def ordered_competitors
          EventCompetitor
            .joins(:competitor)
            .where(event_id: event.id)
            .select('event_competitors.qualifier, competitors.name')
            .map { |competitor| [competitor.qualifier, competitor.name] }
            .to_h
        end
      end
    end
  end
end
