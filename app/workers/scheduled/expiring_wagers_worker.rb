# frozen_string_literal: true

module Scheduled
  class ExpiringWagersWorker < ApplicationWorker
    sidekiq_options queue: 'expired_wagers', lock: :until_executed

    def perform
      EveryMatrix::Requests::ExpireService.call
    end
  end
end
