module SafeCharge
  class Reply
    attr_reader :params, :status, :ppt_status

    def initialize(params)
      @params = params
      @status = params['Status']
      @ppt_status = params['ppp_status']
    end

    def entry_request
      @entry_request ||= EntryRequest.find(entry_request_id)
    end

    def approved?
      check_ppt_status && status.casecmp?(Statuses::APPROVED)
    end

    def pending?
      check_ppt_status && status.casecmp?(Statuses::PENDING)
    end

    def verify_checksum!
      provided_checksum = params['advanceResponseChecksum']
      raise DmnAuthenticationError unless provided_checksum == checksum

      true
    end

    private

    def entry_request_id
      params['merchant_unique_id'].to_i
    end

    def check_ppt_status
      ppt_status.casecmp? Statuses::OK
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
