# frozen_string_literal: true

class CustomerBonusesController < ApplicationController
  find :customer_bonus, only: %i[show destroy]
  find :wallet, by: %i[customer_bonus wallet_id], strict: false, only: :create
  find :original_bonus,
       by: %i[customer_bonus original_bonus_id],
       class: Bonus.name,
       strict: false,
       only: :create

  decorates_assigned :customer_bonus

  def create
    form = CustomerBonuses::Backoffice::CreateForm.new(
      wallet: @wallet,
      bonus: @original_bonus,
      amount: payload_params[:amount],
      initiator: current_user
    )

    @customer_bonus = form.submit!

    redirect_to bonuses_customer_path(@customer_bonus.customer),
                notice: t(:activated, instance: t('entities.bonus'))
  rescue CustomerBonuses::ActivationError,
         EntryRequests::FailedEntryRequestError,
         ActiveModel::ValidationError => error
    redirect_to bonuses_customer_path(@wallet.customer), alert: error.message
  end

  def destroy
    CustomerBonuses::Deactivate.call(
      bonus: @customer_bonus,
      action: CustomerBonuses::Deactivate::CANCEL,
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
