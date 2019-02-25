module Withdrawals
  class WithdrawalRejectionService < ApplicationService
    def initialize(entry_id, comment: nil)
      @entry_id = entry_id
      @comment = comment
    end

    def call
      create_refund!
    end

    private

    attr_reader :entry_id, :comment

    def create_refund!
      refund = EntryRequests::Factories::Refund.call(entry: entry,
                                                     comment: comment)
      EntryRequests::RefundWorker.perform_async(refund.id)
    end

    def entry
      @entry ||= Entry.find(entry_id)
    end
  end
end
