module Backoffice
  class BonusesController < BackofficeController
    def index
      @search = Bonus.search(query_params)
      @bonuses = @search.result.page(params[:page])
    end

    def show
      @bonus = Bonus.find(params[:id])
    end
  end
end
