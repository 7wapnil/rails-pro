class WithdrawalsController < ApplicationController
  before_action :find_withdrawal, only: %i[confirm reject]

  def index
    @withdrawals = Entry.withdraw.page(params[:page])
  end

  def confirm
    @withdrawal.update_attributes!(confirmed_at: Time.zone.now)
    flash[:notice] = I18n.t('messages.withdrawal_confirmed')

    redirect_back fallback_location: withdrawals_path
  end

  def reject
    # TODO : call withdrawal rejection service
    flash[:notice] = I18n.t('messages.withdrawal_rejected')

    redirect_back fallback_location: withdrawals_path
  end

  private

  def find_withdrawal
    @withdrawal = Entry.find(params[:id])
  end

  def rejection_params
    params.require(:rejection).permit(:comment)
  end
end
