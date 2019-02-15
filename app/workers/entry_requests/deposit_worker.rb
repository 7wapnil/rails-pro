# frozen_string_literal: true

module EntryRequests
  class DepositWorker < BaseWorker
    private

    def processing_service
      EntryRequests::DepositService
    end
  end
end
