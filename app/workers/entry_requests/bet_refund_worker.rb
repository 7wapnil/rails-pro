# frozen_string_literal: true

module EntryRequests
  class BetRefundWorker < ApplicationWorker
    def perform(id, *args)
      entry_request = EntryRequest.find(id)

      EntryRequests::BetRefundService.call(
        entry_request: entry_request,
        message: args[:message],
        code: args[:code]
      )
    end
  end
end
