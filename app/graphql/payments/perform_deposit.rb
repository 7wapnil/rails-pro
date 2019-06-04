# frozen_string_literal: true

module Payments
  class PerformDeposit < ::Base::Resolver
    type ::Payments::DepositType

    argument :paymentMethod, ::Payments::DepositPaymentMethodEnum
    argument :currencyCode, !types.String
    argument :amount, !types.Float
    argument :bonusCode, types.String

    def resolve(_obj, args)
      transaction = ::Payments::Transaction.new(
        method: args[:paymentMethod].to_sym,
        customer: current_customer,
        currency: find_currency(args[:currencyCode]),
        amount: args[:amount].to_d,
        bonus_code: args[:bonusCode]
      )

      OpenStruct.new(url: ::Payments::Deposit.call(transaction))
    rescue ::Payments::GatewayError => e
      gateway_error!(e)
    rescue StandardError => e
      system_error!(e)
    end

    private

    def find_currency(currency_code)
      Currency.find_by!(code: currency_code)
    end

    def gateway_error!(error)
      Rails.logger.warn(message: 'Deposit error', error: error.message)
      raise error.message
    end

    def system_error!(error)
      Rails.logger.warn(message: 'Deposit error', error: error.message)
      raise I18n.t('errors.messages.technical_error_happened')
    end
  end
end
