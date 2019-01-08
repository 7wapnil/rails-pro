module PaymentProvider
  class FakeDeposit
    def authorize(_amount, _credit_card, _options = {})
      response_body = {
        success?: true,
        authorization: SecureRandom.hex(16),
        message: 'Authorization message'
      }
      OpenStruct.new(response_body)
    end

    def capture(_amount, _authorization, _options = {})
      true
    end

    def pay!(amount, credit_card, options = {})
      response = authorize(amount, credit_card, options)

      raise(StandardError, response.message) unless response.success?

      capture(amount, credit_card, options)
    end
  end
end
