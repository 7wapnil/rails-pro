module SafeCharge
  class WebhookHandler < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      response.validate!
      return entry_request.succeeded! if response.approved?
      return entry_request.pending! if response.pending?

      entry_request.failed!
    end

    private

    def response
      @response ||= SafeCharge::Response.new(@params)
    end

    def entry_request
      @entry_request ||= response.entry_request
    end
  end
end
