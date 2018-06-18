class AddOriginReferencesToEntryReuqests < ActiveRecord::Migration[5.2]
  def change
    remove_column :entry_requests, :origin_id, :integer
    remove_column :entry_requests, :origin_type, :integer
    add_reference :entry_requests, :origin, polymorphic: true
  end
end
