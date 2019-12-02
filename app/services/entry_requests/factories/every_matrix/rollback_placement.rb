# frozen_string_literal: true

module EntryRequests
  module Factories
    module EveryMatrix
      class RollbackPlacement < BasePlacement
        protected

        def entry_request_kind
          EntryRequest::EVERY_MATRIX_ROLLBACK
        end

        def balance_calculations_service
          BalanceCalculations::EveryMatrix::DebitCalculations
        end
      end
    end
  end
end
