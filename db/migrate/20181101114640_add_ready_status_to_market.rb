class AddReadyStatusToMarket < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :ready, :boolean, default: true
  end
end
