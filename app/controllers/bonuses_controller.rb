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
        'internal.created',
        instance: t('internal.entities.bonus')
      )
    else
      render :new
    end
  end

  def update
    @bonus = Bonus.find(params[:id])

    if @bonus.update(bonus_params)
      redirect_to @bonus, notice: t(
        'internal.updated',
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
      'internal.deleted',
      instance: t('internal.entities.bonus')
    )
  end

  private

  # rubocop:disable Metrics/MethodLength
  def bonus_params
    params.require(:bonus)
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
                  :previous_deposits_number,
                  :limit_per_each_bet_leg,
                  :casino,
                  :sportsbook,
                  :sportsbook_multiplier,
                  :max_rollover_per_spin)
  end
  # rubocop:enable Metrics/MethodLength
end
