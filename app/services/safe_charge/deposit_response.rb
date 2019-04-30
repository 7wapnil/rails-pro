module SafeCharge
  class DepositResponse < Response
    AUTHENTICATION_ERROR = DmnAuthenticationError
    TYPE_ERROR = Deposits::IncompatibleRequestStateError
    PARAMS_MISMATCH = CallbackDataMismatch
    BUSINESS_EXCEPTIONS = [
      AUTHENTICATION_ERROR,
      TYPE_ERROR,
      PARAMS_MISMATCH
    ].freeze

    delegate :real_money_balance_entry_request, to: :entry_request
    delegate :amount, to: :real_money_balance_entry_request, allow_nil: true

    def entry_request
      @entry_request ||= EntryRequest.find(entry_request_id)
    end

    def validate!
      validate_checksum!
      validate_entry_request_state!
      validate_parameters!
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
      params['productId'].to_i
    end

    def validate_parameters!
      valid = true
      valid &&= params['totalAmount'].to_d == amount
      valid &&= params['currency'] == entry_request.currency.code
      raise PARAMS_MISMATCH unless valid
    end
  end
end
