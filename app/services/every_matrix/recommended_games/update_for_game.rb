# frozen_string_literal: true

module EveryMatrix
  module RecommendedGames
    class UpdateForGame < ApplicationService
      def initialize(game)
        @game = game
      end

      def call
        game.update!(
          recommended_games: recommended_games,
          last_updated_recommended_games_at: Time.zone.now
        )
      end

      private

      attr_reader :game

      def recommended_games
        FetchGamesFromApi.call(game)
      end
    end
  end
end
