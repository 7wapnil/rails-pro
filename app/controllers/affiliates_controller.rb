class AffiliatesController < ApplicationController
  PER_PAGE = 20

  def index
    @search = Affiliate.ransack(params[:query])
    @affiliates = @search.result.page(params[:page]).per(PER_PAGE)
  end

  def import
    Affiliates::Import.call(params[:file].path)

    redirect_to affiliates_path, notice: t('interna.import_successful')
  end
end
