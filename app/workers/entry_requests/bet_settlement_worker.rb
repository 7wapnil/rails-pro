# frozen_string_literal: true

module EntryRequests
  class BetSettlementWorker < BaseWorker
    private

    def processing_service
      EntryRequests::BetSettlementService
    end
  end
end
