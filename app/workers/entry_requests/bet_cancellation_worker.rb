# frozen_string_literal: true

module EntryRequests
  class BetCancellationWorker < BaseWorker
    private

    def processing_service
      EntryRequests::RefundService
    end
  end
end
