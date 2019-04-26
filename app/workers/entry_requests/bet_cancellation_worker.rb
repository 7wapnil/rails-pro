# frozen_string_literal: true

module EntryRequests
  class BetCancellationWorker < BaseWorker
    private

    def processing_service
      EntryRequests::ProcessingService
    end
  end
end
