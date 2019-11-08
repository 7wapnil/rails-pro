class BonusesController < ApplicationController
  def index
    @search = Bonus.ransack(query_params)
    @bonuses = @search.result.page(params[:page])
  end

  def show
    @bonus = Bonus.find(params[:id])
  end

  def new
    @bonus = Bonus.new
  end

  def edit
    @bonus = Bonus.find(params[:id])
  end

  def create
    @bonus = Bonus.new(bonus_params)

    if @bonus.save
      redirect_to @bonus, notice: t(
        :created,
        instance: t('entities.bonus')
      )
    else
      render :new
    end
  end

  def update
    @bonus = Bonus.find(params[:id])

    if @bonus.update(bonus_params)
      redirect_to @bonus, notice: t(
        :updated,
        instance: @bonus.code
      )
    else
      render :edit
    end
  end

  def destroy
    @bonus = Bonus.find(params[:id])
    @bonus.destroy!
    redirect_to bonuses_path, notice: t(
      :deleted,
      instance: t('entities.bonus')
    )
  end

  private

  def bonus_params # rubocop:disable Metrics/MethodLength
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
              :valid_for_days,
              :percentage,
              :repeatable,
              :casino)
  end
end
