# frozen_string_literal: true

module EveryMatrix
  class ContentProvidersController < ApplicationController
    find :content_provider, only: %i[edit update],
                            class: EveryMatrix::ContentProvider.name

    def index
      @search = ContentProvider.ransack(query_params)

      @content_providers = @search.result.page(params[:page])
    end

    def update
      return render :edit unless @content_provider.update(provider_params)

      redirect_to every_matrix_content_providers_path
    end

    private

    def provider_params
      params
        .require(:every_matrix_content_provider)
        .permit(
          :name, :visible, :representation_name, :as_vendor,
          :logo_url, :internal_image_name
        )
    end
  end
end
