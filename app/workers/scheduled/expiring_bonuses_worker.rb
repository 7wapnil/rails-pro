# frozen_string_literal: true

module Scheduled
  class ExpiringBonusesWorker < ApplicationWorker
    sidekiq_options queue: 'expired_bonuses', lock: :until_executed

    def perform
      Bonuses::ExpiringBonusesHandler.call
    end
  end
end
