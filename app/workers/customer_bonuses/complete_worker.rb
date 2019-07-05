# frozen_string_literal: true

module CustomerBonuses
  class CompleteWorker < ApplicationWorker
    def perform(customer_bonus_id)
      customer_bonus = CustomerBonus.find(customer_bonus_id)
      CustomerBonuses::Complete.call(customer_bonus: customer_bonus)
    end
  end
end
