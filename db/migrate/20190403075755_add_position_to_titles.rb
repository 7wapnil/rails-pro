class AddPositionToTitles < ActiveRecord::Migration[5.2]
  def change
    add_column :titles, :position, :integer, null: false, default: 999
    add_index  :titles, :position
  end
end
