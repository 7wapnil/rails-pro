# frozen_string_literal: true

module EntryRequests
  class WithdrawalWorker < BaseWorker
    private

    def processing_service
      EntryRequests::WithdrawalService
    end
  end
end
