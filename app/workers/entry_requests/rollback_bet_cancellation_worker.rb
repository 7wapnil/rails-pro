# frozen_string_literal: true

module EntryRequests
  class RollbackBetCancellationWorker < BaseWorker
    private

    def processing_service
      EntryRequests::ProcessingService
    end
  end
end
