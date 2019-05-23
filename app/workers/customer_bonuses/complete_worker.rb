# frozen_string_literal: true

module CustomerBonuses
  class CompleteWorker < ApplicationWorker
    def perform_async(customer_bonus:)
      CustomerBonuses::Complete.call(customer_bonus: customer_bonus)
    end
  end
end
