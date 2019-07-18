# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Payouts
        class CallbackHandler < Handlers::PayoutCallbackHandler
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
end
