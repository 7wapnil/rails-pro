# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class ForfeitBonusWorker < BaseWorker
      private

      def handler_class
        ForfeitBonusHandler
      end
    end
  end
end
