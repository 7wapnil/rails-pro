class AddCustomerNotesDeletedAtColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :customer_notes, :deleted_at, :datetime
    add_index :customer_notes, :deleted_at
  end
end
