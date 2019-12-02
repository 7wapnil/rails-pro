# frozen_string_literal: true

module EntryRequests
  module Factories
    module EveryMatrix
      class ResultPlacement < BasePlacement
        protected

        def entry_request_kind
          EntryRequest::EVERY_MATRIX_RESULT
        end

        def balance_calculations_service
          BalanceCalculations::EveryMatrix::DebitCalculations
        end
      end
    end
  end
end
