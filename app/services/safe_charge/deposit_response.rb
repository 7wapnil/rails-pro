module SafeCharge
  class DepositResponse < Response
    AUTHENTICATION_ERROR = DmnAuthenticationError
    TYPE_ERROR = Deposits::IncompatibleRequestStateError
    BUSINESS_EXCEPTIONS = [AUTHENTICATION_ERROR, TYPE_ERROR].freeze

    def entry_request
      @entry_request ||= EntryRequest.find(entry_request_id)
    end

    def validate!
      validate_checksum!
      validate_entry_request_state!
      true
    end

    private

    def validate_entry_request_state!
      raise TYPE_ERROR unless valid_entry_request_state?
    end

    def valid_entry_request_state?
      entry_request&.kind == EntryRequest::DEPOSIT
    end

    def validate_checksum!
      raise AUTHENTICATION_ERROR unless valid_checksum?
    end

    def valid_checksum?
      params['advanceResponseChecksum'] == checksum
    end

    def entry_request_id
      params['merchant_unique_id'].to_i
    end
  end
end
