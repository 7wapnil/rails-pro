class AddOddsChangeFieldToBets < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :odds_change, :boolean, default: false
  end
end
