# frozen-string_literal: true

module EveryMatrix
  module Requests
    class LaunchUrlBuilder < ApplicationService
      CASINO = 'casino'
      LIVE_CASINO = 'live-casino'

      SLUG_MAP = {
        EveryMatrix::Game.name => CASINO,
        EveryMatrix::Table.name => LIVE_CASINO
      }.freeze

      def initialize(play_item:, session_id: nil)
        @play_item = play_item
        @session_id = session_id
      end

      def call
        session_id.nil? ? fun_launch_url : real_money_launch_url
      end

      private

      attr_reader :play_item, :session_id

      def fun_launch_url
        launch_url
      end

      def launch_url(additional_params = {})
        uri = URI(play_item.url)
        query = Rack::Utils.parse_nested_query(uri.query)
        uri.query = Rack::Utils.build_query(
          query.merge('casinolobbyurl' => lobby_url).merge(additional_params)
        )

        uri.to_s
      end

      def real_money_launch_url
        launch_url(
          'language' => 'en',
          'funMode' => 'False',
          '_sid' => session_id
        )
      end

      def lobby_url
        "#{ENV['FRONTEND_URL']}/#{SLUG_MAP[play_item.type]}"
      end
    end
  end
end
