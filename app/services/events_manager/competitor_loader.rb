module EventsManager
  class CompetitorLoader < BaseEntityLoader
    def call
      competitor = ::Competitor.new(external_id: competitor_data.id,
                                    name: competitor_data.name,
                                    details: competitor_data.details)
      build_players(competitor)
      ::Competitor.create_or_update_on_duplicate(competitor)
      competitor
    end

    private

    def competitor_data
      @competitor_data ||= EventsManager::Entities::Competitor.new(query)
    end

    def query
      api_client.competitor_profile(@external_id)
    end

    def build_players(competitor)
      competitor_data.players.map do |player_data|
        build_player(competitor, player_data)
      end
    end

    def build_player(competitor, player_data)
      player = ::Player.new(external_id: player_data.id,
                            name: player_data.name,
                            full_name: player_data.full_name)
      ::Player.create_or_update_on_duplicate(player)
      competitor.competitor_players.build(player: player)
    end
  end
end
