class AddLimitPerEachBetLegFieldToBonus < ActiveRecord::Migration[5.2]
  def change
    add_column :bonuses, :limit_per_each_bet_leg, :boolean, default: false
  end
end
