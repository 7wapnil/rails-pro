module Backoffice
  class BonusesController < BackofficeController
    def index
      @search = Bonus.search(query_params)
      @bonuses = @search.result.page(params[:page])
    end

    def show
      @bonus = Bonus.find(params[:id])
    end

    def new
      @bonus = Bonus.new
    end

    def create
      @bonus = Bonus.new(create_params)

      if @bonus.save
        redirect_to(backoffice_bonus_path(@bonus),
                    notice: t(:created, instance: t('entities.bonus')))
      else
        render :new
      end
    end

    private

    def create_params
      params
        .require(:bonus)
        .permit(:code,
                :kind,
                :rollover_multiplier,
                :max_rollover_per_bet,
                :expires_at,
                :max_deposit_match,
                :min_odds_per_bet,
                :min_deposit,
                :valid_for_days)
    end
  end
end
