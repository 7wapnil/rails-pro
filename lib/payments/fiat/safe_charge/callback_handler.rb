# frozen_string_literal: true

module Payments
  module Crypto
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
          ::Payments::Crypto::SafeCharge::Deposits::CallbackHandler
        end
      end
    end
  end
end
