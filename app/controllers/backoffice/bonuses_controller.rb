module Backoffice
  class BonusesController < BackofficeController
    def index
      @bonuses = Bonus.all.page(params[:page])
    end
  end
end
