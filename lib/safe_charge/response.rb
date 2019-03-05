module SafeCharge
  class Response
    attr_reader :params, :transaction_status, :payment_message_status

    def initialize(params)
      @params = params
      @transaction_status = params['Status']
      @payment_message_status = params['ppp_status']
    end

    def approved?
      status_ok? && transaction_status.casecmp?(Statuses::APPROVED)
    end

    def pending?
      status_ok? && transaction_status.casecmp?(Statuses::PENDING)
    end

    private

    def status_ok?
      payment_message_status.casecmp? Statuses::OK
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
