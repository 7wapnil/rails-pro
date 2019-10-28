class WithdrawalProcessBackofficeWorker < ApplicationWorker
  def perform(entry_request_id)
    entry_request = EntryRequest.find(entry_request_id)
    entry = WalletEntry::AuthorizationService.call(entry_request)
    entry&.confirm!
  end
end
