module OddsFeed
  module Radar
    module Transpiling
      class NameExpression < BaseExpression
        PLAYER_REGEX     = /%player/
        COMPETITOR_REGEX = /%competitor/
        VENUE_REGEX      = /%venue/
        NAME_SIGN        = '%'.freeze

        def value(token)
          loader_class(token).call(external_id: external_id(token))
        end

        private

        def loader_class(token)
          return Radar::Entities::PlayerLoader     if player?(token)
          return Radar::Entities::CompetitorLoader if competitor?(token)
          return Radar::Entities::VenueLoader      if venue?(token)

          raise "Name transpiler can't read variable: `#{token}`"
        end

        def player?(token)
          token.match?(PLAYER_REGEX)
        end

        def competitor?(token)
          token.match?(COMPETITOR_REGEX)
        end

        def venue?(token)
          token.match?(VENUE_REGEX)
        end

        def external_id(token)
          specifier(token.delete(NAME_SIGN))
        end
      end
    end
  end
end
