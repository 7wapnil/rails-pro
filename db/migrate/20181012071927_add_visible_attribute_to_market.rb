class AddVisibleAttributeToMarket < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :visible, :boolean, default: true
  end
end
