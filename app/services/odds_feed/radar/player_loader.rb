# frozen_string_literal: true

module OddsFeed
  module Radar
    class PlayerLoader < ApplicationService
      def initialize(player_id)
        @player_id = player_id
        @api_client = ::OddsFeed::Radar::Client.instance
      end

      def call
        params = @api_client.player_profile(@player_id)
                            .dig('player_profile', 'player')

        raise ArgumentError, 'Player payload is malformed' unless params

        Player.new(external_id: params['id'],
                   name: params['name'],
                   full_name: params['full_name'])
      end
    end
  end
end
