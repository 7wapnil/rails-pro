# frozen_string_literal: true

module EveryMatrix
  class PlayItemsResolver < ApplicationService
    def initialize(model:, category:, device:, country: '')
      @model = model
      @category = category
      @device = device
      @country = country
    end

    def call
      model
        .joins(:categories)
        .where(condition)
        .public_send(device)
        .activated
        .reject_country(country)
        .order('every_matrix_play_item_categories.position ASC')
    end

    private

    attr_reader :model, :category, :device, :country

    def condition
      {
        every_matrix_categories: {
          id: category.id
        }
      }
    end
  end
end
