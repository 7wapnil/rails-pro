# frozen_string_literal: true

module Payments
  module Deposits
    class Perform < ::Base::Resolver
      type ::Payments::DepositType

      argument :input, Inputs::DepositInput

      def resolve(_obj, args)
        input = args['input']

        raise '`input` has to be passed' unless input

        url = perform_transaction(input)

        OpenStruct.new(url: url,
                       message: I18n.t('payments.deposits.success_message'))
      rescue ::Payments::GatewayError, ::Payments::BusinessRuleError => e
        payment_error!(e)
      rescue StandardError => e
        system_error!(e)
      end

      private

      def perform_transaction(input)
        transaction = ::Payments::Transaction.new(
          method: input[:paymentMethod],
          customer: current_customer,
          currency: find_currency(input[:currencyCode]),
          amount: input[:amount].to_d,
          bonus_code: input[:bonusCode]
        )
        ::Payments::Deposit.call(transaction)
      end

      def find_currency(currency_code)
        Currency.find_by!(code: currency_code)
      end

      def payment_error!(error)
        Rails.logger.warn(message: 'Deposit error', error: error.message)
        raise error.message
      end

      def system_error!(error)
        Rails.logger.warn(message: 'Deposit error', error: error.message)
        raise I18n.t('errors.messages.technical_error_happened')
      end
    end
  end
end
