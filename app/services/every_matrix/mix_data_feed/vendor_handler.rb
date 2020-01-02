# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class VendorHandler < MixDataFeed::BaseHandler
      private

      def handle_update_message
        vendor = EveryMatrix::Vendor
                 .find_or_initialize_by(vendor_id: data['vendorID'])

        vendor.update!(params)
      end

      def params
        {
          enabled: data['enabled'],
          has_live_casino: data['hasLiveCasino'],
          languages: data['languages'],
          currencies: data['currencies'],
          logo_url: https(data.dig('presentation', 'logo', '*')),
          name: data['name'],
          slug: data['name'].underscore.dasherize.tr(' ', '-'),
          restricted_territories: data['restrictedTerritories']
        }
      end

      def https(string)
        return unless string

        "https:#{string}"
      end
    end
  end
end
