# frozen_string_literal: true

module EveryMatrix
  module RecommendedGames
    class FetchGamesFromApi < ApplicationService
      LIMIT_GAMES_FOR_SAVE = 10

      def initialize(game)
        @game = game
      end

      def call
        perform_api_call!

        select_play_items
      end

      private

      attr_reader :game, :response

      def perform_api_call!
        data = build_request.run.body
        @response = data.present? ? JSON.parse(data) : {}
      end

      def select_play_items
        EveryMatrix::PlayItem.where(external_id: response_game_ids)
                             .where.not(external_id: game.id)
                             .order(order_by_rank)
                             .limit(LIMIT_GAMES_FOR_SAVE)
      end

      def order_by_rank
        Arel.sql(
          "position(external_id::text in '#{response_game_ids&.join(',')}')"
        )
      end

      def response_game_ids
        @response_game_ids ||= response['games']&.map { |game| game['id'].to_s }
      end

      def build_request
        Typhoeus::Request.new(
          "#{ENV['EVERY_MATRIX_RECOMMENDED_GAME_URL']}" \
          "/#{ENV['EVERY_MATRIX_OPERATOR_KEY']}",
          method: :get,
          params: { ids: game.id, platform: 'PC' }
        )
      end
    end
  end
end
