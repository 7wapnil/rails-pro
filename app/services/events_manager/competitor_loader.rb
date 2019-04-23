module EventsManager
  class CompetitorLoader < BaseEntityLoader
    def call
      competitor = ::Competitor.new(attributes)
      ::Competitor.create_or_update_on_duplicate(competitor)
      update_players(competitor)

      competitor
    end

    private

    def attributes
      { external_id: competitor_data.id,
        name: competitor_data.name,
        details: competitor_data.details }
    end

    def competitor_data
      @competitor_data ||= EventsManager::Entities::Competitor.new(query)
    end

    def query
      api_client.competitor_profile(@external_id)
    end

    def update_players(competitor)
      competitor_data.players.map do |player_entity|
        update_player(competitor, create_player(player_entity))
      rescue ActiveRecord::RecordInvalid
        Rails.logger.warn "Player data is invalid: #{player_entity}"
      end
    end

    def update_player(competitor, player)
      return if competitor.players.exists?(player.id)

      competitor.players << player
    end

    def create_player(player_entity)
      player = ::Player.new(external_id: player_entity.id,
                            name: player_entity.name,
                            full_name: player_entity.full_name)
      ::Player.create_or_update_on_duplicate(player)
      player
    end
  end
end
