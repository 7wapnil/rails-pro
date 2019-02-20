module SafeCharge
  class CallbackHandler < ApplicationService
    def initialize(params, context)
      @params = params
      @context = context
    end

    def call
      response.validate!
      return success_flow if response.approved?
      return pending_flow if response.pending?
      return back_flow if cancel_context?

      fail_flow
    rescue SafeCharge::Response::AUTHENTICATION_ERROR
      Deposit::CallbackUrl::ERROR
    rescue SafeCharge::Response::TYPE_ERROR
      Deposit::CallbackUrl::FAILED_ENTRY_REQUEST
    rescue StandardError => e
      Rails.logger.error(e.message)
      Deposit::CallbackUrl::SOMETHING_WENT_WRONG
    end

    private

    delegate :entry_request, to: :response, allow_nil: true

    def cancel_context?
      @context == Deposit::CallbackUrl::BACK
    end

    def back_flow
      entry_request.failed!
      Deposit::CallbackUrl::BACK
    end

    def fail_flow
      return Deposit::CallbackUrl::ERROR if entry_request.failed?

      entry_request.failed!
      Deposit::CallbackUrl::ERROR
    end

    def pending_flow
      return Deposit::CallbackUrl::SOMETHING_WENT_WRONG unless pending_context?

      Deposit::CallbackUrl::PENDING
    end

    def pending_context?
      @context == Deposit::CallbackUrl::PENDING
    end

    def success_flow
      return Deposit::CallbackUrl::SUCCESS if entry_request.succeeded?

      return Deposit::CallbackUrl::SOMETHING_WENT_WRONG unless success_context?

      entry_request.succeeded!
      Deposit::CallbackUrl::SUCCESS
    end

    def success_context?
      @context == Deposit::CallbackUrl::SUCCESS
    end

    def response
      @response ||= SafeCharge::Response.new(@params)
    end
  end
end
