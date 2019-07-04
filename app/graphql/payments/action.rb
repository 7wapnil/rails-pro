# frozen_string_literal: true

module Payments
  class Action < ::Base::Resolver
    attr_reader :transaction_result

    def resolve(_obj, args)
      input = args['input']

      raise '`input` has to be passed' unless input

      @transaction_result = perform_transaction(input)

      successful_payment_response
    rescue ::Payments::GatewayError => error
      gateway_error!(error)
    rescue ::Payments::BusinessRuleError => error
      payment_error!(error)
    rescue StandardError => error
      system_error!(error)
    end

    protected

    def perform_transaction(_input)
      raise NotImplementedError, 'Implement #perform_transaction!'
    end

    def successful_payment_response
      raise NotImplementedError, 'Implement #successful_payment_response!'
    end

    def gateway_error!(error)
      Rails.logger.warn(message: "#{action_name} error", error: error.message)
      raise error.message
    end

    def payment_error!(error)
      Rails.logger.warn(message: "#{action_name} error", error: error.message)

      raise(error.message) unless error.attribute

      raise ResolvingError, error.attribute => error.message
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
