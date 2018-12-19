class MarketTemplatesController < ApplicationController
  def index
    @search = MarketTemplate.ransack(query_params)
    @market_templates = @search.result.page(params[:page])
  end

  def update
    @market_template = MarketTemplate.find(params[:id])
    @market_template.update!(market_template_params)
    respond_to :js
  end

  private

  def market_template_params
    params.require(:market_template).permit(:category)
  end
end
