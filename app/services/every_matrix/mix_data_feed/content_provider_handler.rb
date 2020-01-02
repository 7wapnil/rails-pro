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
          logo_url: https(presentation.dig('logo', '*')),
          representation_name: representation_name,
          enabled: data['enabled'],
          slug: representation_name.underscore.dasherize.tr(' ', '-')
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
