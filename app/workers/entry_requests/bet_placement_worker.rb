# frozen_string_literal: true

module EntryRequests
  class BetPlacementWorker < BaseWorker
    private

    def processing_service
      EntryRequests::BetPlacementService
    end
  end
end
