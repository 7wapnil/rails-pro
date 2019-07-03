module WithdrawalHelper
  def withdrawal_statuses(filter)
    selected_status = query_params(:withdrawals)['status_eq']
    selected_status ||= Withdrawal::PENDING
    options_for_select(filter.statuses, selected_status)
  end

  def withdrawal_payment_methods(filter)
    params = query_params(:withdrawals)
    selected_method = params['entry_request_mode_eq']
    options_for_select(filter.payment_methods, selected_method)
  end

  def actioned_by(user)
    "#{t('attributes.actioned_by')} #{user.email}"
  end
end
