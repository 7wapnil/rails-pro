# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    module Games
      class DetailsGenerator < ApplicationService
        LIVEDEALER = 'LIVEDEALER'

        def initialize(data:, game:)
          @data = data
          @game = game
          @property = data['property']
        end

        def call
          return if filtered_game?

          details = EveryMatrix::GameDetails
                    .find_or_initialize_by(play_item_id: game.id)

          details.update!(update_params.compact)
        end

        private

        attr_reader :data, :game, :property

        def filtered_game?
          game.tags.include?(LIVEDEALER)
        end

        def update_params
          {
            help_url: data['help_url'],
            free_spin_supported: free_spin['support'],
            free_spin_bonus_supported: free_spin['supportFeatureBonus'],
            min_hit_frequency: hit_frequency['min'],
            max_hit_frequency: hit_frequency['max'],
            launch_game_in_html_5: property['launchGameInHtml5'],
            top_prize: data['topPrize']
          }
        end

        def free_spin
          property['freeSpin']
        end

        def hit_frequency
          property['hitFrequency']
        end
      end
    end
  end
end
