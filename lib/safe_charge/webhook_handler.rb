module SafeCharge
  class WebhookHandler < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      reply.validate!
      return entry_request.succeeded! if reply.approved?
      return entry_request.pending! if reply.pending?

      entry_request.failed!
    end

    private

    def reply
      @reply ||= SafeCharge::Reply.new(@params)
    end

    def entry_request
      @entry_request ||= reply.entry_request
    end
  end
end
