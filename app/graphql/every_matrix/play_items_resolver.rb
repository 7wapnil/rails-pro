# frozen_string_literal: true

module EveryMatrix
  class PlayItemsResolver < ApplicationService
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
        .order(:position)
    end

    private

    attr_reader :model, :category_name, :device, :country

    def condition
      {
        every_matrix_categories: {
          name: category_name,
          platform_type: device
        }
      }
    end
  end
end
