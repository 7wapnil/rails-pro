# frozen_string_literal: true

module CustomerBonuses
  class CompleteWorker < ApplicationWorker
    def perform(customer_bonus_id)
      CustomerBonuses::Complete.call(customer_bonus_id)
    end
  end
end
