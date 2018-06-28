class AddLabelDeletedAtColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :labels, :deleted_at, :datetime
    add_index :labels, :deleted_at
  end
end
