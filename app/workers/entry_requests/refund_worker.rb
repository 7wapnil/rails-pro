# frozen_string_literal: true

module EntryRequests
  class RefundWorker < BaseWorker
    private

    def processing_service
      EntryRequests::RefundService
    end
  end
end
