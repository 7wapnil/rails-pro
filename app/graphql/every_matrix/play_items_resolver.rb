# frozen_string_literal: true

module EveryMatrix
  class PlayItemsResolver < ApplicationService
    ITEMS_LIMIT = 35

    def initialize(model:, category_name:, device:, country: '')
      @model = model
      @category_name = category_name
      @device = device
      @country = country
    end

    def call
      model
        .joins(:categories)
        .where(condition)
        .reject_country(country)
        .limit(ITEMS_LIMIT)
    end

    private

    attr_reader :model, :category_name, :device, :country

    def condition
      {
        every_matrix_categories: {
          name: category_name,
          platform_type: platform_type
        }
      }
    end

    def platform_type
      return Category::MOBILE if device.mobile? || device.tablet?

      Category::DESKTOP
    end
  end
end
