class WithdrawalRequestsController < ApplicationController
  mutations = %i[confirm reject]
  before_action :create_audit_log, only: mutations

  def index
    query_params = query_params(:withdrawal_requests)
    query_params[:status_eq] ||= WithdrawalRequest::PENDING
    @filter = WithdrawalRequestFilter.new source: WithdrawalRequest,
                                          query_params: query_params,
                                          page: params[:page]
  end

  def confirm
    @withdrawal_request.confirm!(current_user)
    flash[:notice] = I18n.t('messages.withdrawal_confirmed')
  rescue StandardError => e
    flash[:error] = e.message
  ensure
    redirect_back fallback_location: withdrawal_requests_path
  end

  def reject
    comment = rejection_params[:comment]
    @withdrawal_request.reject!(current_user, comment)
    flash[:notice] = I18n.t('messages.withdrawal_rejected')
  rescue StandardError => e
    flash[:error] = e.message
  ensure
    redirect_back fallback_location: withdrawal_requests_path
  end

  private

  def withdrawal_request
    @withdrawal_request ||= WithdrawalRequest.find(params[:id])
  end

  def rejection_params
    params.require(:rejection).permit(:comment)
  end

  def create_audit_log
    event = "withdrawal_request_#{action_name}".to_s
    Audit::Service.call(event: event,
                        user: current_user,
                        customer: withdrawal_request.entry.customer,
                        context: withdrawal_request)
  end
end
