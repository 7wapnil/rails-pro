module Deposits
  class EntryRequestUrlService < ApplicationService
    def initialize(entry_request:)
      @entry_request = entry_request
    end

    def call
      return request_failure_url if @entry_request.failed?
      return request_success_url if @entry_request.initial?

      raise(
        'Entry request URL is not available for state ' +
          @entry_request.status
      )
    end

    private

    def request_failure_url
      Deposits::CallbackUrl
        .for(:failed_entry_request,
             message: result_message_from_entry_request)
    end

    def result_message_from_entry_request
      @entry_request.result['message']
    end

    def request_success_url
      Deposits::GetPaymentPageUrl
        .call(entry_request: @entry_request)
    end
  end
end
