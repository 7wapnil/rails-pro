# frozen_string_literal: true

module Payments
  module Fiat
    module SafeCharge
      module Payouts
        class RequestHandler < Handlers::PayoutRequestHandler
          # TODO: add functionality for programmatic payout
          def call
            withdrawal.succeeded!
          end
        end
      end
    end
  end
end
