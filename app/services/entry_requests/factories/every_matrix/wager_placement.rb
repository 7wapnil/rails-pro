# frozen_string_literal: true

module EntryRequests
  module Factories
    module EveryMatrix
      class WagerPlacement < BasePlacement
        protected

        def entry_request_kind
          EntryRequest::EM_WAGER
        end

        def balance_calculations_service
          BalanceCalculations::EveryMatrix::Wager
        end
      end
    end
  end
end
