# frozen_string_literal: true

module EveryMatrix
  class GamesProviderResolver < ApplicationService
    def call
      all_providers.map.with_index do |obj, index|
        OpenStruct.new(
          id: index,
          name: obj.try(:representation_name) || obj.name,
          logoUrl: obj.logo_url,
          enabled: obj.enabled,
          internalImageName: obj.internal_image_name,
          slug: obj.slug
        )
      end
    end

    private

    def all_providers
      providers = [*EveryMatrix::ContentProvider.visible.as_vendor.distinct,
                   *EveryMatrix::Vendor.visible.distinct]

      providers.sort_by(&method(:sort_algorithm))
    end

    def sort_algorithm(provider)
      return Float::INFINITY unless provider.position

      provider.position
    end
  end
end
