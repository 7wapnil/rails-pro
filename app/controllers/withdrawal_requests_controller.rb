class WithdrawalRequestsController < ApplicationController
  mutations = %i[confirm reject]
  before_action :save_acting_user, only: mutations
  before_action :create_audit_log, only: mutations

  def index
    query_params = query_params(:withdrawal_requests)
    @filter = WithdrawalRequestFilter.new source: WithdrawalRequest,
                                          query_params: query_params,
                                          page: params[:page]
  end

  def confirm
    entry.update!(confirmed_at: Time.now.utc)
    @withdrawal_request.update!(status: WithdrawalRequest::APPROVED)

    flash[:notice] = I18n.t('messages.withdrawal_confirmed')
    redirect_back fallback_location: withdrawal_requests_path
  end

  def reject
    reason = rejection_params[:comment]
    Withdrawals::WithdrawalRejectionService.call(entry.id,
                                                 comment: reason)
    @withdrawal_request.update!(status: WithdrawalRequest::REJECTED)
    flash[:notice] = I18n.t('messages.withdrawal_rejected')
    redirect_back fallback_location: withdrawal_requests_path
  end

  private

  def withdrawal_request
    @withdrawal_request ||= WithdrawalRequest.find(params[:id])
  end

  def entry
    @withdrawal_request.entry_request.entry
  end

  def rejection_params
    params.require(:rejection).permit(:comment)
  end

  def save_acting_user
    withdrawal_request
    @withdrawal_request.update!(actioned_by: current_user)
  end

  def create_audit_log
    withdrawal_request
    event = "withdrawal_request_#{action_name}".to_s
    Audit::Service.call(event: event,
                        user: current_user,
                        customer: @withdrawal_request.entry_request.customer,
                        context: @withdrawal_request)
  end
end
