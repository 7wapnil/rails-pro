module SafeCharge
  class WebhookHandler < ApplicationService
    def initialize(params)
      @reply = reply(params)
    end

    def call
      @reply.verify_checksum!
      return entry_request.succeeded! if @reply.approved?
      return entry_request.pending! if @reply.pending?

      entry_request.failed!
    end

    private

    def reply(params)
      SafeCharge::Reply.new(params)
    end

    def entry_request
      @entry_request ||= @reply.entry_request
    end
  end
end
