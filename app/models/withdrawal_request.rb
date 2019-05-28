# frozen_string_literal: true

class WithdrawalRequest < CustomerTransaction
  def loggable_attributes
    { id: id, status: status }
  end

  def confirm!(user)
    review!(user, APPROVED)
    entry.update!(confirmed_at: Time.zone.now)
  end

  def reject!(user, comment)
    comment_error = I18n.t('errors.messages.withdrawal_requests.empty_comment')
    raise comment_error if comment.empty?

    review!(user, REJECTED)
    Withdrawals::WithdrawalRejectionService.call(entry.id, comment: comment)
  end

  private

  def review!(user, new_status)
    error_message = I18n.t('errors.messages.withdrawal_requests.not_actionable')
    raise error_message unless pending?

    update!(actioned_by: user, status: new_status)
  end
end
