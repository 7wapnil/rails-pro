# frozen_string_literal: true

module EntryRequests
  module Factories
    module EveryMatrix
      class WagerPlacement < BasePlacement
        protected

        def entry_request_kind
          EntryRequest::EVERY_MATRIX_WAGER
        end

        def balance_calculations_service
          BalanceCalculations::EveryMatrix::CreditCalculations
        end
      end
    end
  end
end
