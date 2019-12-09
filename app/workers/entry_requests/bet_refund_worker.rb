# frozen_string_literal: true

module EntryRequests
  class BetRefundWorker < ApplicationWorker
    def perform(id, code, message, details)
      entry_request = EntryRequest.find(id)

      EntryRequests::BetRefundService.call(
        entry_request: entry_request,
        message: message,
        code: code,
        details: details
      )
    end
  end
end
