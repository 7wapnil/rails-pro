class AddSystemMarkerToLabel < ActiveRecord::Migration[5.2]
  def change
    add_column :labels, :system, :boolean, default: false
    add_column :labels, :keyword, :string, unique: true
    add_index :labels, :keyword, unique: true
  end
end
