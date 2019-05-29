# frozen_string_literal: true

module EntryRequests
  class BonusChangeWorker < BaseWorker
    private

    def processing_service
      EntryRequests::BonusChangeService
    end
  end
end
