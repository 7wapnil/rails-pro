class AddPriorityToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :priority, :integer
  end
end
