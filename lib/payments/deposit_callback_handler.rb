# frozen_string_literal: true

module Payments
  class DepositCallbackHandler < ::ApplicationService
    delegate :origin, to: :entry_request, prefix: true
    delegate :customer_bonus, to: :entry_request_origin

    protected

    attr_reader :response

    def request_id
      raise NotImplementedError, 'Implement #request_id method!'
    end

    def entry_request
      @entry_request ||= ::EntryRequest.find(request_id)
    end

    def fail_related_entities
      customer_bonus&.fail!
      entry_request&.origin&.failed!
    end
  end
end