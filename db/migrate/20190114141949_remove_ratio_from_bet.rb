class RemoveRatioFromBet < ActiveRecord::Migration[5.2]
  def change
    remove_column :bets, :ratio
  end
end
