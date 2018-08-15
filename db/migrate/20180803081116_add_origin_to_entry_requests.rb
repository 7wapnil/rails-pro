class AddOriginToEntryRequests < ActiveRecord::Migration[5.2]
  def change
    add_reference :entry_requests, :origin, polymorphic: true, index: true
  end
end
