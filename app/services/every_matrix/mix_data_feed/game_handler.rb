# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class GameHandler < MixDataFeed::BaseHandler
      private

      def handle_update_message
        return delete_game! if data.nil?

        create_or_update_game!
      end

      def delete_game!
        EveryMatrix::Game.find_by(external_id: data['id'])&.destroy!
      end

      def create_or_update_game!
        game = EveryMatrix::Game.find_or_create_by(external_id: data['id'])
        game.with_lock { game.update!(game_attributes) }
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def game_attributes
        {
          slug: data['slug'],
          vendor: data['vendor'],
          content_provider: data['contentProvider'],
          categories: data['categories'],
          theoretical_payout: data['theoreticalPayOut'],
          third_party_fee: data['thirdPartyFee'],
          fpp: data['fpp'],
          restricted_territories: data['restrictedTerritories'],
          languages: data['languages'],
          currencies: data['currencies'],
          url: data['url'],
          help_url: data['help_url'],
          external_created_at: creation['time'],
          external_updated_at: creation['lastModified'],
          default_coin: property['defaultCoin'],
          free_spin_supported: free_spin['support'],
          free_spin_bonus_supported: free_spin['supportFeatureBonus'],
          min_hit_frequency: hit_frequency['min'],
          max_hit_frequency: hit_frequency['max'],
          launch_game_in_html_5: property['launchGameInHtml5'],
          popularity_coefficient: popularity['coefficient'],
          popularity_ranking: popularity['ranking'],
          play_mode_fun: play_mode['fun'],
          play_mode_anonymity: play_mode['anonymity'],
          play_mode_real_money: play_mode['realMoney'],
          name: presentation['gameName']['*'],
          short_name: presentation['shortName']['*'],
          thumbnail_url: presentation['thumbnail']['*'],
          logo_url: presentation['logo']['*'],
          background_image_url: presentation['backgroundImage']['*'],
          small_icon_url: presentation.dig('icons', '44', '*'),
          medium_icon_url: presentation.dig('icons', '72', '*'),
          large_icon_url: presentation.dig('icons', '114', '*'),
          top_prize: data['topPrize']
        }
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def creation
        data['creation']
      end

      def property
        data['property']
      end

      def free_spin
        property['freeSpin']
      end

      def hit_frequency
        property['hitFrequency']
      end

      def popularity
        data['popularity']
      end

      def play_mode
        data['playMode']
      end

      def presentation
        data['presentation']
      end
    end
  end
end
