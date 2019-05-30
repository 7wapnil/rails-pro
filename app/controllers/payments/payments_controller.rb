module Payments
  class PaymentsController < ActionController::Base
    skip_before_action :verify_authenticity_token

    # TODO: Remove after testing
    def test # rubocop:disable Metrics/MethodLength
      test_customer = Customer.find(params[:customer_id])

      transaction = ::Payments::Transaction.new(
        method: payment_method,
        customer: test_customer,
        currency: currency,
        amount: request_params[:amount].to_d,
        bonus_code: request_params[:bonus_code]
      )

      payment_page_url = ::Payments::Deposit.call(transaction)
      render inline: "<a href=\"#{payment_page_url}\" target=\"_blank\">Link to payment page is here</a>" # rubocop:disable Metrics/LineLength
    rescue ::Payments::GatewayError => e
      render plain: "Gateway errors: #{e.message}"
    rescue StandardError => e
      render plain: "Standard errors: #{e.message}"
    end

    def deposit # rubocop:disable Metrics/MethodLength
      transaction = ::Payments::Transaction.new(
        method: payment_method,
        customer: customer,
        currency: currency,
        amount: request_params[:amount].to_d,
        bonus_code: request_params[:bonus_code]
      )

      redirect_to ::Payments::Deposit.call(transaction)
    rescue ::Payments::GatewayError => e
      log_message(:error, e.message)
      redirect_to return_customer_url(:failed, e.message)
    rescue StandardError => e
      log_message(:error, e.message)
      redirect_to return_customer_url(
        :failed,
        I18n.t('errors.messages.technical_error_happened')
      )
    end

    def notification
      Rails.logger.debug "Notification received: #{params}"
      render plain: provider.handle_payment_response(params)
    rescue StandardError => e
      log_message(:error, e.message)
      render plain: "Standard errors: #{e.message}"
      # redirect_to return_customer_url(:failed, e.message)
    end

    def provider
      raise ::NotImplementedError
    end

    protected

    def return_customer_url(state, message = nil)
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
      customer_id = JwtService.extract_user_id(user_token)
      Customer.find(customer_id)
    end

    def currency
      Currency.find_by!(code: request_params[:currency_code])
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
