# frozen_string_literal: true

module Payments
  class Action < ::Base::Resolver
    attr_reader :transaction_result

    def resolve(_obj, args)
      input = args['input']

      raise '`input` has to be passed' unless input

      @transaction_result = perform_transaction(input)

      successful_payment_response
    rescue ::Payments::GatewayError, ::Payments::BusinessRuleError => e
      payment_error!(e)
    rescue StandardError => e
      system_error!(e)
    end

    protected

    def perform_transaction(_input)
      raise NotImplementedError, 'Implement #perform_transaction!'
    end

    def successful_payment_response
      raise NotImplementedError, 'Implement #successful_payment_response!'
    end

    def payment_error!(error)
      Rails.logger.warn(message: "#{action_name} error", error: error.message)
      raise error.message
    end

    def action_name
      @action_name ||= self.class.superclass.name.singularize
    end

    def system_error!(error)
      Rails.logger.warn(message: "#{action_name} error", error: error.message)
      raise I18n.t('errors.messages.technical_error_happened')
    end
  end
end
