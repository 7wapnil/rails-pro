module EventsManager
  class CompetitorLoader < BaseEntityLoader
    def call
      load_competitor
    rescue StandardError => e
      log :warn,
          message: 'Unable to create competitor',
          error: e.message,
          external_id: @external_id,
          competitor_data: competitor_data.to_s
      nil
    end

    private

    def load_competitor
      competitor = ::Competitor.new(attributes)
      ::Competitor.create_or_update_on_duplicate(competitor)
      log :info,
          message: 'Competitor updated',
          competitor_id: competitor.external_id

      update_players(competitor)

      competitor
    end

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
        log :warn,
            message: 'Player data is invalid',
            player: player_entity.to_s
      end
    end

    def update_player(competitor, player)
      ::CompetitorPlayer.create_or_ignore_on_duplicate(
        ::CompetitorPlayer.new(competitor: competitor, player: player)
      )
    end

    def create_player(player_entity)
      player = ::Player.new(external_id: player_entity.id,
                            name: player_entity.name,
                            full_name: player_entity.full_name)
      ::Player.create_or_update_on_duplicate(player)
      log :info, message: 'Player updated', player_id: player_entity.id

      player
    end
  end
end
