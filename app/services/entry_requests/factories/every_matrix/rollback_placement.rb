# frozen_string_literal: true

module EntryRequests
  module Factories
    module EveryMatrix
      class RollbackPlacement < BasePlacement
        protected

        def entry_request_kind
          EntryRequest::EM_ROLLBACK
        end

        def balance_calculations_service
          BalanceCalculations::EveryMatrix::Rollback
        end
      end
    end
  end
end
