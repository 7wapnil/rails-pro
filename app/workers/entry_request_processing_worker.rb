class EntryRequestProcessingWorker < ApplicationWorker
  def perform(entry_request_id)
    entry_request = EntryRequest.find(entry_request_id)
    WalletEntry::AuthorizationService.call(entry_request)
  end
end
