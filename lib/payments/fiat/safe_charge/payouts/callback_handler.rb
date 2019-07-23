# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Payouts
        class CallbackHandler < Handlers::PayoutCallbackHandler
          # TODO: add functionality for programmatic payout
          def call; end
        end
      end
    end
  end
end
