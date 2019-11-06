# frozen_string_literal: true

module EveryMatrix
  class PlayItemsResolver < ApplicationService
    ITEMS_LIMIT = 35

    def initialize(model:, category:, device:, country: '')
      @model = model
      @category = category
      @device = device
      @country = country
    end

    def call
      model
        .items_per_category(category)
        .where(every_matrix_categories: { platform_type: platform_type })
        .reject_country(country)
        .limit(ITEMS_LIMIT)
    end

    private

    attr_reader :model, :category, :device, :country

    def platform_type
      return Category::MOBILE if device.mobile? || device.tablet?

      Category::DESKTOP
    end
  end
end
