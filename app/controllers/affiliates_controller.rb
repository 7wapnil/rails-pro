class AffiliatesController < ApplicationController
  PER_PAGE = 20

  def index
    @search = Affiliate.ransack(params[:query])
    @affiliates = @search.result.page(params[:page]).per(PER_PAGE)
  end

  def import
    result = Affiliates::Import.call(params[:file].path)

    redirect_to affiliates_path, notice: result.message
  end
end
