# frozen_string_literal: true

module EveryMatrix
  class PlayItemsResolver < ApplicationService
    def initialize(model:, category_name:, device:)
      @model = model
      @category_name = category_name
      @device = device
    end

    def call
      model
        .joins(:categories)
        .where(condition)
        .public_send(device)
        .order('every_matrix_play_item_categories.position ASC')
    end

    private

    attr_reader :model, :category_name, :device

    def condition
      {
        every_matrix_categories: {
          context: category_name
        }
      }
    end
  end
end
