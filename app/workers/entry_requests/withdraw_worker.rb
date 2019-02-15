# frozen_string_literal: true

module EntryRequests
  class WithdrawWorker < BaseWorker
    private

    def processing_service
      Withdrawals::WithdrawalService
    end
  end
end
