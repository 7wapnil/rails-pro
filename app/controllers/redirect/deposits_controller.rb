module Redirect
  class DepositsController < ActionController::Base
    skip_before_action :verify_authenticity_token, only: :webhook

    def initiate
      entry_request =
        ::Deposits::InitiateHostedDepositService.call(
          customer: customer,
          currency: currency_by_code,
          amount: initiate_params[:amount],
          bonus_code: initiate_params[:bonus_code]
        )

      entry_request.save!

      redirect_to Deposits::EntryRequestUrlService
        .call(entry_request: entry_request)
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      Rails.logger.error 'Deposit request with corrupted data received.'
      callback(:something_went_wrong)
    end

    def success
      # TODO: Change entry_request state
      callback(:success)
    end

    def error
      # TODO: Change entry_request state
      callback(:error)
    end

    def pending
      callback(:pending)
    end

    def back
      # TODO: Change entry_request state
      callback(:back)
    end

    def webhook
      # TODO: Change entry_request state
      SafeCharge::WebhookHandler.call(params)

      head :ok
    end

    private

    def currency_by_code
      Currency.find_by(code: initiate_params[:currency_code])
    end

    def customer
      decoded_token =
        JwtService.decode(initiate_params[:token])[0].symbolize_keys
      Customer.find(decoded_token[:id])
    end

    def callback(state)
      redirect_to Deposit::CallbackUrl.for(state)
    end

    def initiate_params
      params.permit(:token, :currency_code, :amount, :bonus_code)
    end
  end
end
