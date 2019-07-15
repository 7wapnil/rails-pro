# frozen_string_literal: true

module Scheduled
  class ExpiringCustomerBonusesWorker < ApplicationWorker
    def perform
      CustomerBonus.initial
                   .where('created_at < ?', 1.day.ago)
                   .find_each(&:expire!)
    end
  end
end
