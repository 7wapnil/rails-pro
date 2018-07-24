class AddOddValueColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :odds, :value, :decimal
  end
end
