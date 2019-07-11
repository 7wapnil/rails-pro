# frozen_string_literal: true

module Payments
  module Wirecard
    module Payouts
      class CallbackHandler < ::Payments::PayoutCallbackHandler
        def initialize(response)
          @response = response
        end

        def call
          # TODO: add functionality for programmatic payout
        end
      end
    end
  end
end
