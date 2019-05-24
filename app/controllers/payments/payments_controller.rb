module Payments
  class PaymentsController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def deposit
      console

      transaction = ::Payments::Transaction.new(
        method: payment_method,
        customer: customer,
        currency: currency,
        amount: request_params[:amount].to_d,
        bonus_code: request_params[:bonus_code]
      )

      payment_page_url = ::Payments::Deposit.call(transaction)
      render inline: "<a href=\"#{payment_page_url}\" target=\"_blank\">Link to payment page is here</a>" # rubocop:disable Metrics/LineLength
    rescue StandardError => e
      log_message(:error, e.message)
      render plain: e.message
    end

    def notification
      raise ::NotImplementedError
    end

    def provider
      raise ::NotImplementedError
    end

    protected

    def return_customer_url(state, message)
      URI(ENV['FRONTEND_URL']).tap do |uri|
        uri.query =
          { depositState: state,
            depositStateMessage: message }.compact.to_query
      end.to_s
    end

    def log_message(level, message = nil)
      Rails.logger.send(level, message: message)
    end

    private

    def customer
      Customer.first
      # customer_id = JwtService.extract_user_id(user_token)
      # Customer.find(customer_id)
    end

    def currency
      Currency.find_by!(code: 'EUR')
      # Currency.find_by!(code: request_params[:currency_code])
    end

    def request_params
      params.permit(:method, :token, :currency_code, :amount, :bonus_code)
    end

    def user_token
      request_params[:token]
    end

    def payment_method
      request_params[:method].to_sym
    end
  end
end
