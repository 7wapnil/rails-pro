module Redirect
  class DepositsController < ActionController::Base
    skip_before_action :verify_authenticity_token, only: :webhook

    def initiate # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      entry_request =
        ::Deposits::InitiateHostedDepositService.call(
          customer: customer,
          currency: currency_by_code,
          amount: initiate_params[:amount].to_d,
          bonus_code: initiate_params[:bonus_code]
        )

      entry_request.save!

      redirect_to Deposits::EntryRequestUrlService
        .call(entry_request: entry_request)
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError => e
      Rails.logger.error(
        'Deposit request with corrupted data received. ' + e.message
      )
      callback_redirect_for(Deposits::CallbackUrl::ERROR)
    rescue Deposits::DepositAttemptError
      Rails.logger.error 'Customer deposit attempts exceeded.'
      callback_redirect_for(Deposits::CallbackUrl::DEPOSIT_ATTEMPTS_EXCEEDED)
    rescue StandardError => e
      msg = 'Something went wrong on deposit initiation.'
      Rails.logger.error msg + e.message.to_s
      callback_redirect_for(Deposits::CallbackUrl::SOMETHING_WENT_WRONG)
    end

    def success
      callback(Deposits::CallbackUrl::SUCCESS)
    end

    def error
      callback(Deposits::CallbackUrl::ERROR)
    end

    def pending
      callback(Deposits::CallbackUrl::PENDING)
    end

    def back
      callback(Deposits::CallbackUrl::BACK)
    end

    def callback(context)
      # TODO: Verify balances updated accordingly
      state = SafeCharge::CallbackHandler.call(params, context)
      callback_redirect_for(state)
    end

    def webhook
      # TODO: Verify balances updated accordingly
      SafeCharge::WebhookHandler.call(params)

      head :ok
    rescue StandardError => e
      Rails.logger.fatal(e.message)

      head :internal_server_error
    end

    private

    def currency_by_code
      Currency.find_by!(code: initiate_params[:currency_code])
    rescue ActiveRecord::RecordNotFound
      message =
        "Currency with code #{initiate_params[:currency_code]} not found."
      raise ActiveRecord::RecordNotFound.new, message
    end

    def customer
      decoded_token =
        JwtService.decode(initiate_params[:token])[0].symbolize_keys
      Customer.find(decoded_token[:id])
    end

    def callback_redirect_for(state)
      redirect_to Deposits::CallbackUrl.for(state)
    end

    def initiate_params
      params.permit(:token, :currency_code, :amount, :bonus_code)
    end
  end
end
