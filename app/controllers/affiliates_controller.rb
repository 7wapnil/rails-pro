class AffiliatesController < ApplicationController
  PER_PAGE = 20

  def index
    @affiliates = Affiliate.page(params[:page]).per(PER_PAGE)
  end
end
