# frozen_string_literal: true

module Entries
  class PostProcessEntryWorker < ApplicationWorker
    def perform(entry_id)
      entry = Entry.find(entry_id)

      WalletEntry::PostAuthorizationService.call(entry)
    end
  end
end
