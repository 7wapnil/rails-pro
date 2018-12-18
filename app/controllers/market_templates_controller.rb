class MarketTemplatesController < ApplicationController
  def index
    @search = MarketTemplate.ransack(query_params)
    @market_templates = @search.result.page(params[:page])
  end
end
