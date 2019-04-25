class CustomerBonusesController < ApplicationController
  def create
    wallet = Wallet.find(payload_params[:wallet_id])
    bonus = Bonus.find(payload_params[:original_bonus_id])
    amount = payload_params[:amount].to_f
    customer_bonus = Bonuses::ActivationService.call(wallet, bonus, amount)
    customer = wallet.customer
    flash[:success] = t(:activated, instance: t('entities.bonus'))
    bonus_activated(customer_bonus, customer)
  rescue CustomerBonuses::ActivationError => error
    flash[:error] = error.message
  ensure
    redirect_to bonuses_customer_path(customer)
  end

  def show
    @customer_bonus = CustomerBonus
                      .includes(:customer)
                      .with_deleted
                      .find(params[:id])
  end

  def destroy
    bonus = CustomerBonus.find(params[:id])
    bonus.close!(BonusExpiration::Expired,
                 reason: :manual_cancel,
                 user: current_user)
    redirect_to bonuses_customer_path(bonus.customer)
  end

  private

  def payload_params
    params
      .require(:customer_bonus)
      .permit(
        :original_bonus_id,
        :wallet_id,
        :amount
      )
  end

  def bonus_activated(customer_bonus, customer)
    current_user.log_event :bonus_activated, customer_bonus, customer
    customer_bonus.add_funds(payload_params[:amount].to_i)
  end
end
