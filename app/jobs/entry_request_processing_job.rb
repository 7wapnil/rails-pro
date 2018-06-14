class EntryRequestProcessingJob < ApplicationJob
  queue_as :default

  def perform(entry_request)
    WalletEntry::Service.call(entry_request)
  end
end
