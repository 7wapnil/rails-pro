class AddReadyColumnToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :ready, :boolean, default: false
  end
end
