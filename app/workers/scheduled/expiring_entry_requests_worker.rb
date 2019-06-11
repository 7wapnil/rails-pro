# frozen_string_literal: true

module Scheduled
  class ExpiringEntryRequestsWorker < ApplicationWorker
    sidekiq_options queue: 'expired_entry_requests', lock: :until_executed

    def perform
      EntryRequest.deposit.expired.find_each do |entry_request|
        entry_request.register_failure!('Entry request was expired')
        entry_request.origin&.customer_bonus&.fail!
      end
    end
  end
end
