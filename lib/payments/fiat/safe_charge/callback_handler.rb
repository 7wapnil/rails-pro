# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class CallbackHandler < ::ApplicationService
        def initialize(response)
          @response = response
        end

        def call
          log_response
          callback_handler.call(response)
        end

        private

        attr_reader :response

        def log_response
          Rails.logger.info(
            message: 'SafeCharge deposit callback',
            **response.to_h.deep_symbolize_keys
          )
        end

        def callback_handler
          ::Payments::Fiat::SafeCharge::Deposits::CallbackHandler
        end
      end
    end
  end
end
