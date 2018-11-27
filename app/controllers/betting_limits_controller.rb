class BettingLimitsController < ApplicationController
  def create
    @betting_limit = BettingLimit.create!(payload_params)
    customer = @betting_limit.customer
    current_user.log_event :betting_limit_created, @betting_limit, customer
    redirect_to betting_limits_customer_path(customer)
  end

  def update
    @betting_limit = BettingLimit.find(params[:id])
    @betting_limit.update!(payload_params)
    customer = @betting_limit.customer
    current_user.log_event :betting_limit_updated, @betting_limit, customer
    redirect_to betting_limits_customer_path(customer)
  end

  private

  def payload_params
    params
      .require(:betting_limit)
      .permit(
        :customer_id,
        :title_id,
        :live_bet_delay,
        :user_max_bet,
        :max_loss,
        :max_win,
        :user_stake_factor,
        :live_stake_factor
      )
  end
end
