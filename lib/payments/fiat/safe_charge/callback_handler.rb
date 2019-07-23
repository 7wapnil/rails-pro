# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      class CallbackHandler < ::ApplicationService
        def initialize(response)
          @response = response
        end

        def call
          callback_handler.call(response)
        end

        private

        attr_reader :response

        def callback_handler
          ::Payments::Fiat::SafeCharge::Deposits::CallbackHandler
        end
      end
    end
  end
end
