# frozen_string_literal: true

module EveryMatrix
  module FreeSpinBonuses
    class AwardBonusWorker < BaseWorker
      private

      def handler_class
        AwardBonusHandler
      end
    end
  end
end
