module SafeCharge
  class WebhookHandler < TransactionResponseHandler
    def call
      super

      # TODO: Store external_id for pending requests
      return if response.pending?

      return succeed_entry_request! if response.approved?

      entry_request.failed!
    end

    private

    delegate :entry_request, to: :response

    def response
      @response ||= SafeCharge::DepositResponse.new(params)
    end
  end
end
