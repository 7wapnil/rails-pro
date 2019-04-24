class AddCorruptedFlagToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :corrupted, :boolean, default: false
    add_index  :events, :corrupted
  end
end
