module Payments
  class PaymentResponse < ::ApplicationService
    STATUS_SUCCESS = :success
    STATUS_FAILED = :failed
    STATUS_PENDING = :pending
    STATUS_CANCELED = :cancelled

    def initialize(response)
      @response = response
    end

    def call
      return if pending?

      return fail_entry_request! if failed? || canceled?

      complete_entry_request!
    end

    def entry_request
      @entry_request ||= ::EntryRequest.find(request_id)
    end

    def success?
      status == STATUS_SUCCESS
    end

    def failed?
      status == STATUS_FAILED
    end

    def canceled?
      status == STATUS_CANCELED
    end

    def pending?
      status == STATUS_PENDING
    end

    def message; end

    def status
      raise ::NotImplementedError
    end

    def request_id
      raise ::NotImplementedError
    end

    private

    def fail_entry_request!
      entry_request.register_failure!(message)
    end

    def complete_entry_request!
      wallet = Wallet.find_or_create_by!(
        customer: entry_request.customer,
        currency: entry_request.currency
      )
      entry_request.update(origin: wallet)
      ::EntryRequests::DepositService.call(entry_request: entry_request)
    end
  end
end
