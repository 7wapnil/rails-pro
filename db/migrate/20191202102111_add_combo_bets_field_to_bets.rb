class AddComboBetsFieldToBets < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :combo_bets, :boolean, default: false
  end
end
