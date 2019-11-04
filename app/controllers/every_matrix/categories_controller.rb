# frozen_string_literal: true

module EveryMatrix
  class CategoriesController < ApplicationController
    find :category, only: %i[update edit], class: EveryMatrix::Category

    def index
      @categories = EveryMatrix::Category.all.order(:id)
    end

    def update
      return render 'edit' unless @category.update(category_params)

      trigger_categories_update(@category)

      redirect_to every_matrix_categories_path
    end

    private

    def category_params
      params
        .require(:every_matrix_category)
        .permit(:icon, :name, :position, :kind, :label, :platform_type)
    end

    def trigger_categories_update(category)
      WebSocket::Client.instance.trigger_categories_update(category)
    end
  end
end
