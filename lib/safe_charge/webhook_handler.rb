module SafeCharge
  class WebhookHandler < ApplicationService
    def initialize(params)
      @params = params
      @status = params['Status']
      @ppt_status = params['ppp_status']
    end

    def call
      verify_checksum!
      return entry_request.succeeded! if approved?
      return entry_request.pending! if pending?

      entry_request.failed!
    end

    private

    attr_reader :params, :status, :ppt_status

    def entry_request
      @entry_request ||= EntryRequest.find(params['merchant_unique_id'])
    end

    def approved?
      check_ppt_status && status.casecmp?(Statuses::APPROVED)
    end

    def pending?
      check_ppt_status && status.casecmp?(Statuses::PENDING)
    end

    def check_ppt_status
      ppt_status.casecmp? Statuses::OK
    end

    def verify_checksum!
      provided_checksum = params['advanceResponseChecksum']
      raise DmnAuthenticationError unless provided_checksum == checksum
    end

    def checksum
      Digest::SHA256.hexdigest(checksum_string)
    end

    def checksum_string
      [
        ENV['SAFECHARGE_SECRET_KEY'],
        params['totalAmount'],
        params['currency'],
        params['responseTimeStamp'],
        params['PPP_TransactionID'],
        params['Status'],
        params['productId']
      ].join
    end
  end
end
