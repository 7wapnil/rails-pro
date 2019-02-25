module Withdrawals
  class WithdrawalRejectionService < ApplicationService
    def initialize(entry_id)
      @entry_id = entry_id
    end

    def call
      create_refund!
    end

    private

    attr_reader :entry_id

    def create_refund!
      refund = EntryRequests::Factories::Refund.call(entry: entry)
      EntryRequests::RefundWorker.perform_async(refund.id)
    end

    def entry
      @entry ||= Entry.find(entry_id)
    end
  end
end
