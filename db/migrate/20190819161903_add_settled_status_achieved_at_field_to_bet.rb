class AddSettledStatusAchievedAtFieldToBet < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :bet_settlement_status_achieved_at, :datetime
  end
end
