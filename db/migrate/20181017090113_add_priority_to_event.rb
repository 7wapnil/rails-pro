class AddPriorityToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :priority, :integer, limit: 2, default: 1
  end
end
