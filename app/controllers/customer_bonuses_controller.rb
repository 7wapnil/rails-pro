# frozen_string_literal: true

class CustomerBonusesController < ApplicationController
  find :customer_bonus, only: :destroy
  find :wallet, by: %i[customer_bonus wallet_id], strict: false, only: :create
  find :original_bonus,
       by: %i[customer_bonus original_bonus_id],
       class: Bonus.name,
       strict: false,
       only: :create

  def create
    @customer_bonus = CustomerBonuses::Create.call(
      wallet: @wallet,
      original_bonus: @original_bonus,
      amount: payload_params[:amount],
      update_wallet: true,
      user: current_user
    )

    redirect_to bonuses_customer_path(@customer_bonus.customer),
                notice: t(:activated, instance: t('entities.bonus'))
  rescue CustomerBonuses::ActivationError => error
    redirect_to bonuses_customer_path(@wallet.customer), alert: error.message
  end

  def show
    @customer_bonus = CustomerBonus
                      .includes(:customer)
                      .with_deleted
                      .find(params[:id])
  end

  def destroy
    CustomerBonuses::Deactivate.call(
      bonus: @customer_bonus,
      action: :cancel!,
      user: current_user
    )
    redirect_to bonuses_customer_path(@customer_bonus.customer)
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
end
