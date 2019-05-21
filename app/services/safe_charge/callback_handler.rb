module SafeCharge
  class CallbackHandler < TransactionResponseHandler
    def call
      super
      return success_flow if response.approved?
      return pending_flow if response.pending?
      return back_flow if cancel_context?

      fail_flow
    rescue SafeCharge::DepositResponse::AUTHENTICATION_ERROR
      Deposits::CallbackUrl::ERROR
    rescue SafeCharge::DepositResponse::TYPE_ERROR
      Deposits::CallbackUrl::FAILED_ENTRY_REQUEST
    rescue StandardError => e
      Rails.logger.error(e.message)
      Deposits::CallbackUrl::SOMETHING_WENT_WRONG
    end

    private

    def cancel_context?
      @context == Deposits::CallbackUrl::BACK
    end

    def back_flow
      fail_deposit_request!
      Deposits::CallbackUrl::BACK
    end

    def fail_flow
      fail_deposit_request!
      Deposits::CallbackUrl::ERROR
    end

    def pending_flow
      return Deposits::CallbackUrl::SOMETHING_WENT_WRONG unless pending_context?

      Deposits::CallbackUrl::PENDING
    end

    def pending_context?
      @context == Deposits::CallbackUrl::PENDING
    end

    def success_flow
      return Deposits::CallbackUrl::SOMETHING_WENT_WRONG unless success_context?

      succeed_entry_request!
      Deposits::CallbackUrl::SUCCESS
    end

    def success_context?
      @context == Deposits::CallbackUrl::SUCCESS
    end

    def fail_deposit_request!
      entry_request.failed!
      deposit_request = entry_request.origin
      deposit_request&.customer_bonus&.fail!
    end
  end
end
