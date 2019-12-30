# frozen_string_literal: true

module EveryMatrix
  class VendorsController < ApplicationController
    find :vendor, only: %i[edit update],
                  class: EveryMatrix::Vendor.name

    def index
      @search = Vendor.ransack(query_params)

      @vendors = @search.result.page(params[:page])
    end

    def update
      return render :edit unless @vendor.update(vendor_params)

      redirect_to every_matrix_vendors_path
    end

    private

    def vendor_params
      params
        .require(:every_matrix_vendor)
        .permit(:name, :visible, :logo_url, :internal_image_name, :slug)
    end
  end
end
