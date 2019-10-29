# frozen_string_literal: true

module EveryMatrix
  module MixDataFeed
    class ContentProviderHandler < MixDataFeed::BaseHandler
      private

      def handle_update_message
        content_provider = EveryMatrix::ContentProvider
                           .find_or_initialize_by(name: data['identifying'])

        content_provider.update!(update_params)
      end

      def update_params
        {
          logo_url: presentation.dig('logo', '*'),
          representation_name: presentation.dig('contentProviderName', '*'),
          enabled: data['enabled']
        }
      end

      def presentation
        data['presentation']
      end
    end
  end
end
