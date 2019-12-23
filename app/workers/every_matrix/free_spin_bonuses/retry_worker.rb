# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class RetryWorker < BaseWorker
      private

      def handler_class
        RetryHandler
      end
    end
  end
end
