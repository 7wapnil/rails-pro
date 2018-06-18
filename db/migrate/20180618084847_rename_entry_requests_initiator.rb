class RenameEntryRequestsInitiator < ActiveRecord::Migration[5.2]
  def change
    remove_reference :entry_requests, :origin, polymorphic: true
    add_reference :entry_requests, :initiator, polymorphic: true
  end
end
