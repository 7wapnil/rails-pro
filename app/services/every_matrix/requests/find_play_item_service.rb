# frozen_string_literal: true

module EveryMatrix
  module Requests
    class FindPlayItemService < ApplicationService
      def initialize(em_game_id:, game_code:, device:)
        @em_game_id = em_game_id
        @game_code = game_code
        @device = device
      end

      def call
        find_by_id || find_by_code_and_device || find_by_code!
      end

      private

      attr_reader :em_game_id, :game_code, :device

      def find_by_id
        model.find_by(external_id: em_game_id)
      end

      def model
        EveryMatrix::PlayItem
      end

      def find_by_code_and_device
        model
          .public_send(device)
          .find_by(*game_code_query)
      end

      def game_code_query
        ['lower(game_code) = ?', game_code.downcase]
      end

      def find_by_code!
        Rails.logger.info(
          message: 'Primary play item lookup failed. Trying fallback method',
          em_game_id: em_game_id,
          game_code: game_code,
          device: device
        )

        model.find_by!(*game_code_query)
      end
    end
  end
end
