# frozen_string_literal: true

class Withdrawal < CustomerTransaction
  def loggable_attributes
    { id: id, status: status }
  end

  def confirm!(user)
    review!(user, PROCESSING)
    Withdrawals::ProcessPayout.call(self)
  end

  def reject!(user, comment)
    comment_error = I18n.t('internal.errors.messages.withdrawals.empty_comment')
    raise comment_error if comment.empty?

    review!(user, REJECTED)
    return unless entry

    Withdrawals::WithdrawalRejectionService.call(entry.id, comment: comment)
  end

  private

  def review!(user, new_status)
    return update!(actioned_by: user, status: new_status) if pending?

    raise I18n.t('internal.errors.messages.withdrawals.not_actionable')
  end
end
