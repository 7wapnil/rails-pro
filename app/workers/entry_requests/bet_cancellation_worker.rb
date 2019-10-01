# frozen_string_literal: true

module EntryRequests
  class BetCancellationWorker < ApplicationWorker
    def perform(id, status)
      entry_request = EntryRequest.find(id)

      EntryRequests::BetCancellationService.call(
        entry_request: entry_request,
        status_code: status
      )
    end
  end
end
