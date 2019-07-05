# frozen_string_literal: true

module Scheduled
  class ExpiringCustomerBonusesWorker < ApplicationWorker
    def perform
      CustomerBonus.initial
                   .where('created_at < ?', 24.hours.ago)
                   .find_each(&:expire!)
    end
  end
end
