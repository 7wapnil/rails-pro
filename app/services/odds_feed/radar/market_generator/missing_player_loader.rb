# frozen_string_literal: true

module OddsFeed
  module Radar
    module MarketGenerator
      class MissingPlayerLoader < ApplicationService
        include JobLogger

        def initialize(event, external_id)
          @event = event
          @external_id = external_id
        end

        def call
          return @missing_player if find_or_create_player!

          raise StandardError,
                "Player with id #{external_id} can not be fetched"
        end

        private

        attr_reader :event, :external_id

        def find_or_create_player!
          event.competitors.find do |competitor|
            players = payload(competitor)
                      .dig('competitor_profile', 'players', 'player')
            @missing_player = missing_player(players)

            @missing_player && player(@missing_player, competitor)
          end
        end

        def missing_player(players)
          players.find { |player| player['id'] == external_id }
        end

        def payload(competitor)
          OddsFeed::Radar::Client
            .new
            .competitor_profile(competitor.external_id)
        end

        def player(player_params, competitor)
          persisted_player = persisted_player(player_params)
          persisted_competitor_player(competitor, persisted_player)

          persisted_player
        end

        def persisted_player(params)
          player = ::Player.new(name: params['name'],
                                external_id: params['id'],
                                full_name: params['full_name'])

          Player.create_or_update_on_duplicate(player)

          player
        end

        def persisted_competitor_player(competitor, persisted_player)
          competitor_player = ::CompetitorPlayer.new(player: persisted_player,
                                                     competitor: competitor)
          CompetitorPlayer.create_or_ignore_on_duplicate(competitor_player)
        end
      end
    end
  end
end
