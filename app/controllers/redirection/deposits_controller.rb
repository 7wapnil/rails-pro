module Redirection
  class DepositsController < ActionController::Base
    def initiate
      entry_request =
        ::Deposits::InitiateHostedDepositService.call(
          customer,
          initiate_params[:currency_code],
          initiate_params[:amount],
          initiate_params[:bonus_code]
        )

      redirect_to initiate_request_url(entry_request)
    end

    def success
      callback(:success)
    end

    def error
      callback(:error)
    end

    def pending
      callback(:pending)
    end

    def back
      callback(:back)
    end

    def webhook
      head :ok
    end

    private

    def initiate_request_url(entry_request)
      return request_failure_url(entry_request) if entry_request.failed?

      request_success_url(entry_request)
    end

    def customer
      decoded_token =
        JwtService.decode(initiate_params[:token])[0].symbolize_keys
      Customer.find(decoded_token[:id])
    end

    def request_failure_url(entry_request)
      URI(ENV['FRONTEND_URL']).tap do |uri|
        uri.query =
          { success: 'false',
            id: entry_request.id,
            reason: entry_request.result }.to_query
      end.to_s
    end

    def request_success_url(_entry_request)
      # TODO: Generate safecharge URL
      ENV['SAFECHARGE_HOSTED_PAYMENTS_URL']
    end

    def callback(state)
      redirect_to ENV['FRONTEND_URL'] + '?state=' + state
    end

    def initiate_params
      params.permit(:token, :currency_code, :amount, :bonus_code)
    end
  end
end
