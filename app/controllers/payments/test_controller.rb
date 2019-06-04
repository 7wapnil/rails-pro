# frozen_string_literal: true

module Payments
  class TestController < ActionController::Base
    skip_before_action :verify_authenticity_token

    # TODO: Remove after testing
    def create # rubocop:disable Metrics/MethodLength
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

    private

    def currency
      Currency.find_by!(code: request_params[:currency_code])
    end

    def request_params
      params.permit(:method, :token, :currency_code, :amount, :bonus_code)
    end

    def payment_method
      request_params[:method].to_sym
    end
  end
end
