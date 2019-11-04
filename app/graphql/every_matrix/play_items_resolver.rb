# frozen_string_literal: true

module EveryMatrix
  class PlayItemsResolver < ApplicationService
    ITEMS_LIMIT = 35

    def initialize(model:, category:, device:)
      @model = model
      @category = category
      @device = device
    end

    def call
      model
        .items_per_category(category)
        .where(every_matrix_categories: { platform_type: platform_type })
        .limit(ITEMS_LIMIT)
    end

    private

    attr_reader :model, :category, :device

    def platform_type
      return Category::MOBILE if device.mobile? || device.tablet?

      Category::DESKTOP
    end
  end
end
