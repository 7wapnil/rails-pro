# frozen_string_literal: true

module EntryRequests
  class RollbackBetCancellationWorker < BaseWorker
    private

    def processing_service
      EntryRequests::RefundService
    end
  end
end
