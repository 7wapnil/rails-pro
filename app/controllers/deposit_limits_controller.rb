class DepositLimitsController < ApplicationController
  def create
    deposit_limit = DepositLimit.create!(payload_params)
    customer = deposit_limit.customer
    current_user.log_event :deposit_limit_created,
                           deposit_limit,
                           customer
    redirect_to deposit_limit_customer_path(customer)
  end

  def update
    deposit_limit = DepositLimit.find(params[:id])
    deposit_limit.update!(payload_params)
    customer = deposit_limit.customer
    current_user.log_event :deposit_limit_updated,
                           deposit_limit,
                           customer
    redirect_to deposit_limit_customer_path(customer)
  end

  def destroy
    deposit_limit = DepositLimit.find(params[:id])
    customer = deposit_limit.customer
    deposit_limit.destroy!
    current_user.log_event :deposit_limit_deleted,
                           nil,
                           customer
    redirect_to deposit_limit_customer_path(customer)
  end

  private

  def payload_params
    params
      .require(:deposit_limit)
      .permit(
        :customer_id,
        :currency_id,
        :value,
        :range
      )
  end
end
