module WithdrawalRequestHelper
  def withdrawal_request_status_options(filter)
    selected_status = query_params(:withdrawal_requests)['status_eq']
    options_for_select(filter.statuses, selected_status)
  end

  def withdrawal_request_payment_method_options(filter)
    selected_method = query_params(:withdrawal_requests)['entry_request_mode_eq']
    options_for_select(filter.payment_methods, selected_method)
  end
end
