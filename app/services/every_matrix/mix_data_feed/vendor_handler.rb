# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class VendorHandler < MixDataFeed::BaseHandler
      private

      def deactivate_object!
        EveryMatrix::Vendor.find_by!(name: payload['id']).deactivated!

        Rails.logger.info(message: 'Vendor deactivated on EM side',
                          vendor_name: payload['id'])
      end

      def handle_update_message
        vendor = EveryMatrix::Vendor
                 .find_or_initialize_by(vendor_id: data['vendorID'])

        vendor.update!(params.compact)
      end

      def params
        {
          enabled: data['enabled'],
          has_live_casino: data['hasLiveCasino'],
          languages: data['languages'],
          currencies: data['currencies'],
          logo_url: https(data.dig('presentation', 'logo', '*')),
          name: data['name'],
          restricted_territories: data['restrictedTerritories'],
          external_status: Vendor::ACTIVATED
        }
      end

      def https(string)
        return unless string

        "https:#{string}"
      end
    end
  end
end
