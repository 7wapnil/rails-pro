class WithdrawalRequestsController < ApplicationController
  mutations = %i[confirm reject]
  before_action :find_withdrawal_request, only: mutations
  before_action :save_acting_user, only: mutations
  before_action :create_audit_log, only: mutations

  def index
    @filter = WithdrawalRequestFilter.new source: WithdrawalRequest,
                                          query_params: query_params(:withdrawal_requests), 
                                          page: params[:page]
  end

  def confirm
    @withdrawal_request.update!(status: WithdrawalRequest::APPROVED)

    flash[:notice] = I18n.t('messages.withdrawal_confirmed')
    redirect_back fallback_location: withdrawal_requests_path
  end

  def reject
    reason = rejection_params[:comment]
    # Withdrawals::WithdrawalRejectionService.call(@withdrawal_request.entry_request.entry_id,
    #                                              comment: reason)
    @withdrawal_request.update!(status: WithdrawalRequest::REJECTED)
    flash[:notice] = I18n.t('messages.withdrawal_rejected')
    redirect_back fallback_location: withdrawal_requests_path
  end

  private

  def find_withdrawal_request
    @withdrawal_request ||= WithdrawalRequest.find(params[:id])
  end

  def rejection_params
    params.require(:rejection).permit(:comment)
  end

  def save_acting_user
    find_withdrawal_request
    @withdrawal_request.update!(actioned_by: current_user)
  end

  def create_audit_log
    find_withdrawal_request
    event = "withdrawal_request_#{action_name}".to_s
    Audit::Service.call(event: event,
                        user: current_user,
                        customer: @withdrawal_request.entry_request.customer,
                        context: @withdrawal_request)
  end
end
