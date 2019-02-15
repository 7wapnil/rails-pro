# frozen_string_literal: true

module EntryRequests
  class BaseWorker < ApplicationWorker
    def perform(entry_request_id)
      entry_request = EntryRequest.find(entry_request_id)

      processing_service.call(entry_request: entry_request)
    end

    protected

    def processing_service
      raise NotImplementedError,
            'Method #processing_service has to be implemented!'
    end
  end
end
