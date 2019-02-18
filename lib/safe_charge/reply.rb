module SafeCharge
  class Reply
    AUTHENTICATION_ERROR = DmnAuthenticationError
    BUSINESS_EXCEPTIONS = [AUTHENTICATION_ERROR].freeze

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

    def validate!
      validate_checksum!
      true
    end

    private

    def validate_checksum!
      raise DmnAuthenticationError unless valid_checksum?
    end

    def valid_checksum?
      params['advanceResponseChecksum'] == checksum
    end

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
