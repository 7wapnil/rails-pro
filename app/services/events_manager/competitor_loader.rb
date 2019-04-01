module EventsManager
  class CompetitorLoader < BaseEntityLoader
    def call
      ::Competitor
        .create_with(name: competitor_data.name,
                     details: competitor_data.details,
                     players: players)
        .find_or_create_by(external_id: competitor_data.id)
    end

    private

    def competitor_data
      @competitor_data ||= EventsManager::Entities::Competitor.new(query)
    end

    def query
      api_client.competitor_profile(@external_id)
    end

    def players
      competitor_data.players.map do |player_data|
        ::Player
          .create_with(name: player_data.name,
                       full_name: player_data.full_name)
          .find_or_create_by(external_id: player_data.id)
      end
    end
  end
end
