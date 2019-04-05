module WithdrawalRequests
  class Review < ApplicationService
    def initialize(withdrawal_request:, user:, action:, comment: nil)
      @withdrawal_request = withdrawal_request
      @user = user
      @action = action
      @comment = comment
    end

    def call
      return unless validate_action?

      send(@action)
      @withdrawal_request.update!(update_params)
    end

    def confirm
      entry.update!(confirmed_at: Time.zone.now)
    end

    def reject
      Withdrawals::WithdrawalRejectionService.call(entry.id, comment: @comment)
    end

    private

    def update_params
      { actioned_by: @user, status: status }
    end

    def status
      if @action == :confirm
        WithdrawalRequest::APPROVED
      elsif @action == :reject
        WithdrawalRequest::REJECTED
      end
    end

    def validate_action?
      %i[confirm reject].include? @action
    end

    def entry
      @withdrawal_request.entry_request.entry
    end
  end
end
