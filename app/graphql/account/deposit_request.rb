module Account
  class DepositRequest < ::Base::Resolver
    argument :input, !Account::DepositRequestInput
    type Account::DepositRequestResponse

    def auth_protected?
      true
    end

    def resolve(_obj, args)
      input = args[:input]
      return unless input

      entry_request =
        ::Deposits::InitiateHostedDepositService.call(
          build_request_params(input.to_h)
        )

      deposit_request_response(entry_request)
    end

    private

    def deposit_request_response(entry_request)
      OpenStruct.new(
        success: !entry_request.failed?,
        result: entry_request.result,
        url: safecharge_url(entry_request)
      )
    end

    def build_request_params(input)
      {
        customer: @current_customer,
        currency: currency(input),
        amount: input['amount'],
        bonus_code: input['bonus_code']
      }
    end

    def currency(input)
      Currency.find_by(code: input['currency_code'])
    end

    def safecharge_url(entry_request)
      return '' if entry_request.failed?

      ENV['SAFECHARGE_HOSTED_PAYMENTS_URL']
    end
  end
end
