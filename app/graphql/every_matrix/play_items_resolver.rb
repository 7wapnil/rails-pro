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
        .public_send(device)
        .reject_country(country)
        .order('every_matrix_play_item_categories.position ASC')
    end

    private

    attr_reader :model, :category_name, :device, :country

    def condition
      {
        every_matrix_categories: {
          context: category_name
        }
      }
    end
  end
end
