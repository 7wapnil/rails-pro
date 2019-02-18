module Redirect
  class DepositsController < ActionController::Base
    skip_before_action :verify_authenticity_token, only: :webhook

    def initiate # rubocop:disable Metrics/MethodLength
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
      callback_redirect_for(Deposit::CallbackUrl::ERROR)
    rescue Deposits::DepositAttemptError
      Rails.logger.error 'Customer deposit attempts exceeded.'
      callback_redirect_for(Deposit::CallbackUrl::DEPOSIT_ATTEMPTS_EXCEEDED)
    rescue StandardError
      Rails.logger.error 'Something went wrong on deposit initiation'
      callback_redirect_for(Deposit::CallbackUrl::SOMETHING_WENT_WRONG)
    end

    def success
      callback(Deposit::CallbackUrl::SUCCESS)
    end

    def error
      callback(Deposit::CallbackUrl::ERROR)
    end

    def pending
      callback(Deposit::CallbackUrl::PENDING)
    end

    def back
      callback(Deposit::CallbackUrl::BACK)
    end

    def callback(context)
      # TODO: Verify balances updated accordingly
      state = SafeCharge::CallbackHandler.call(params, context)
      callback_redirect_for(state)
    end

    def webhook
      # TODO: Verify balances updated accordingly
      SafeCharge::WebhookHandler.call(params)
    ensure
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

    def callback_redirect_for(state)
      redirect_to Deposit::CallbackUrl.for(state)
    end

    def initiate_params
      params.permit(:token, :currency_code, :amount, :bonus_code)
    end
  end
end
