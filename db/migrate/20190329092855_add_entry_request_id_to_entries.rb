class AddEntryRequestIdToEntries < ActiveRecord::Migration[5.2]
  def change
    add_reference :entries, :entry_request, index: true
    add_foreign_key :entries, :entry_requests
  end
end
