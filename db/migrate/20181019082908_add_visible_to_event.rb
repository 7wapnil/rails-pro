class AddVisibleToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :visible, :boolean, default: true
  end
end
