module WithdrawalRequestHelper
  def withdrawal_request_statuses(filter)
    selected_status = query_params(:withdrawal_requests)['status_eq']
    selected_status ||= WithdrawalRequest::PENDING
    options_for_select(filter.statuses, selected_status)
  end

  def withdrawal_request_payment_methods(filter)
    params = query_params(:withdrawal_requests)
    selected_method = params['entry_request_mode_eq']
    options_for_select(filter.payment_methods, selected_method)
  end
end
