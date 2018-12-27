class AddActiveToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :active, :boolean, default: false
    add_index :events, :active
  end
end
