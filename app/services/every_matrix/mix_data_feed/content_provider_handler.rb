# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class ContentProviderHandler < MixDataFeed::BaseHandler
      private

      def deactivate_object!
        EveryMatrix::ContentProvider
          .find_by!(external_id: payload['id']).deactivated!

        Rails.logger.info(message: 'Content provider deactivated on EM side',
                          content_provider_external_id: payload['id'])
      end

      def handle_update_message
        content_provider = EveryMatrix::ContentProvider
                           .find_or_initialize_by(name: data['identifying'])

        content_provider.update!(update_params.compact)
      end

      def update_params
        {
          logo_url: https(presentation.dig('logo', '*')),
          representation_name: representation_name,
          enabled: data['enabled'],
          external_status: ContentProvider::ACTIVATED
        }
      end

      def presentation
        data['presentation']
      end

      def representation_name
        presentation.dig('contentProviderName', '*')
      end

      def https(string)
        return unless string

        "https:#{string}"
      end
    end
  end
end
