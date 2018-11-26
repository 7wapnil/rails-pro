class DepositLimitsController < ApplicationController
  def create
    @deposit_limit = DepositLimit.create!(payload_params)
    current_user.log_event :deposit_limit_updated
    redirect_to gambling_limits_customer_path(@deposit_limit.customer)
  end

  def update
    @deposit_limit = DepositLimit.find(params[:id])
    @deposit_limit.update!(payload_params)
    current_user.log_event :deposit_limit_updated
    redirect_to gambling_limits_customer_path(@deposit_limit.customer)
  end

  def destroy
    @deposit_limit = DepositLimit.find(params[:id])
    @deposit_limit.destroy!
    current_user.log_event :deposit_limit_deleted

    redirect_to gambling_limits_customer_path(@deposit_limit.customer)
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
