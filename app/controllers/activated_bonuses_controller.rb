class ActivatedBonusesController < ApplicationController
  def create
    wallet = Wallet.find(payload_params[:wallet_id])
    bonus = Bonus.find(payload_params[:original_bonus_id])
    activated_bonus = Bonuses::ActivationService.call(wallet, bonus)
    customer = wallet.customer
    if activated_bonus.nil?
      flash[:error] = t('errors.messages.bonus_activation_failed')
    else
      flash[:success] = t(:activated, instance: t('entities.bonus'))
      current_user.log_event :bonus_activated, activated_bonus, customer

      activated_bonus.add_funds(payload_params[:amount].to_i)
    end
    redirect_to bonuses_customer_path(customer)
  end

  private

  def payload_params
    params
      .require(:activated_bonus)
      .permit(
        :original_bonus_id,
        :wallet_id,
        :amount
      )
  end
end
