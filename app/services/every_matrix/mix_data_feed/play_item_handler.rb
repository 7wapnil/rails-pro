# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class PlayItemHandler < MixDataFeed::BaseHandler
      protected

      def assign_details!(_params)
        raise NotImplementedError, 'Implement #assign_details method'
      end

      def play_item_type
        raise NotImplementedError, 'Implement #play_item_type method'
      end

      private

      def handle_update_message
        return delete_play_item! if data.nil?

        create_or_update_play_item!
      end

      def delete_play_item!
        EveryMatrix::PlayItem.find_by(external_id: data['id'])&.destroy!
      end

      def create_or_update_play_item!
        play_item = EveryMatrix::PlayItem
                    .find_or_initialize_by(external_id: data['id'])

        play_item.update!(play_item_attributes)
        assign_details!(play_item)
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def play_item_attributes
        {
          type: play_item_type,
          slug: data['slug'],
          vendor: vendor,
          tags: data['categories'],
          content_provider: content_provider,
          theoretical_payout: data['theoreticalPayOut'],
          third_party_fee: data['thirdPartyFee'],
          fpp: data['fpp'],
          restricted_territories: data['restrictedTerritories'],
          languages: data['languages'],
          currencies: data['currencies'],
          url: data['url'],
          external_created_at: creation['time'],
          external_updated_at: creation['lastModified'],
          popularity_coefficient: popularity['coefficient'],
          popularity_ranking: popularity['ranking'],
          play_mode_fun: play_mode['fun'],
          play_mode_anonymity: play_mode['anonymity'],
          play_mode_real_money: play_mode['realMoney'],
          name: presentation.dig('gameName', '*'),
          short_name: presentation.dig('shortName', '*'),
          description: presentation.dig('description', '*'),
          thumbnail_url: https(presentation.dig('thumbnail', '*')),
          logo_url: https(presentation.dig('logo', '*')),
          background_image_url: https(presentation.dig('backgroundImage', '*')),
          small_icon_url: https(presentation.dig('icons', '44', '*')),
          medium_icon_url: https(presentation.dig('icons', '72', '*')),
          large_icon_url: https(presentation.dig('icons', '114', '*')),
          terminal: https(data.dig('property', 'terminal'))
        }
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def vendor
        EveryMatrix::Vendor.find_by!(vendor_id: data['vendorID'])
      end

      def content_provider
        EveryMatrix::ContentProvider
          .find_by!(representation_name: data['contentProvider'])
      end

      def creation
        data['creation']
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

      def https(string)
        return unless string

        "https:#{string}"
      end
    end
  end
end
