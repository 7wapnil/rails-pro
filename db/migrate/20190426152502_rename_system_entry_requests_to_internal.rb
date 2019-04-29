class RenameSystemEntryRequestsToInternal < ActiveRecord::Migration[5.2]
  def change
    EntryRequest.where(mode: 'system').update(mode: 'internal')
  end
end
