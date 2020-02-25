class WithdrawalsController < ApplicationController
  find :withdrawal, except: :index

  attr_reader :withdrawal

  mutations = %i[confirm reject]
  before_action :create_audit_log, only: mutations

  def index
    query_params = query_params(:withdrawals)
    query_params[:status_eq] ||= Withdrawal::PENDING
    @filter = WithdrawalFilter.new source: Withdrawal,
                                   query_params: query_params,
                                   page: params[:page]
  end

  def confirm
    withdrawal.confirm!(current_user)
    flash[:notice] = I18n.t('internal.messages.withdrawal_confirmed')
  rescue Payments::InvalidTransactionError => error
    flash[:error] = error.validation_errors.messages.first.flatten.join(': ')
  rescue StandardError => e
    flash[:error] = e.message
  ensure
    redirect_back fallback_location: withdrawals_path
  end

  def reject
    comment = rejection_params[:comment]
    withdrawal.reject!(current_user, comment)
    flash[:notice] = I18n.t('internal.messages.withdrawal_rejected')
  rescue StandardError => e
    flash[:error] = e.message
  ensure
    redirect_back fallback_location: withdrawals_path
  end

  private

  def rejection_params
    params.require(:rejection).permit(:comment)
  end

  def create_audit_log
    Audit::Service.call(event: "withdrawal_#{action_name}",
                        user: current_user,
                        customer: withdrawal.entry_request.customer,
                        context: withdrawal)
  end
end
