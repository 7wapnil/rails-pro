# frozen_string_literal: true

module EntryRequests
  class RefundWorker < BaseWorker
    private

    def processing_service
      EntryRequests::ProcessingService
    end
  end
end
