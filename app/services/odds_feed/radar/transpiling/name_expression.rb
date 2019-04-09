module OddsFeed
  module Radar
    module Transpiling
      class NameExpression < BaseExpression
        PLAYER_REGEX     = /%player/
        COMPETITOR_REGEX = /%competitor|%server/
        VENUE_REGEX      = /%venue/
        NAME_SIGN        = '%'.freeze

        def value(token)
          return player_name(token)     if player?(token)
          return competitor_name(token) if competitor?(token)
          return venue_name(token)      if venue?(token)

          raise "Name transpiler can't read variable: `#{token}`"
        end

        private

        def player?(token)
          token.match?(PLAYER_REGEX)
        end

        def competitor?(token)
          token.match?(COMPETITOR_REGEX)
        end

        def venue?(token)
          token.match?(VENUE_REGEX)
        end

        def player_name(token)
          event.players.find_by!(external_id: external_id(token)).full_name
        end

        def competitor_name(token)
          event.competitors.find_by!(external_id: external_id(token)).name
        end

        def venue_name(token)
          Radar::Entities::VenueLoader.call(external_id: external_id(token))
        end

        def external_id(token)
          specifier(token.delete(NAME_SIGN))
        end
      end
    end
  end
end
