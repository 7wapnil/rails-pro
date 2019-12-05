# frozen_string_literal: true

module EveryMatrix
  class CategoriesController < ApplicationController
    find :category, only: %i[update edit], class: EveryMatrix::Category

    def index
      @categories = EveryMatrix::Category.all.order(:id)
    end

    def update
      result = Categories::UpdateService.call(
        category: @category,
        params: category_params
      )

      return redirect_to every_matrix_categories_path if result

      render :edit
    end

    private

    def category_params
      params
        .require(:every_matrix_category)
        .permit(:icon, :context, :position, :kind, :label, :platform_type)
    end
  end
end
