# frozen_string_literal: true

module EveryMatrix
  class RecommendedGamesResolver < ApplicationService
    LIMIT_RECOMMENDED_GAMES = 4
    HOURS_BETWEEN_UPDATES = 24

    def initialize(original_game_id:, device:, country: '')
      @original_game_id = original_game_id
      @device = device
      @country = country
    end

    def call
      update_recommended!

      original_game.recommended_games
                   .public_send(device)
                   .reject_country(country)
                   .limit(LIMIT_RECOMMENDED_GAMES)
    end

    private

    attr_reader :original_game_id, :country, :device

    def original_game
      @original_game ||= EveryMatrix::PlayItem.find(original_game_id)
    end

    def update_recommended!
      return if HOURS_BETWEEN_UPDATES.hours.ago.to_i < latest_update

      EveryMatrix::RecommendedGames::UpdateForGame.call(original_game)
    end

    def latest_update
      original_game.last_updated_recommended_games_at.to_i
    end
  end
end
