class AddMaxRolloverPerSpinToBonuses < ActiveRecord::Migration[5.2]
  def up
    add_column :bonuses, :max_rollover_per_spin, :decimal
    add_column :customer_bonuses, :max_rollover_per_spin, :decimal

    execute <<~SQL
      UPDATE bonuses SET max_rollover_per_spin = max_rollover_per_bet
    SQL
    execute <<~SQL
      UPDATE customer_bonuses SET max_rollover_per_spin = max_rollover_per_bet
    SQL
  end

  def down
    remove_column :bonuses, :max_rollover_per_spin
    remove_column :customer_bonuses, :max_rollover_per_spin
  end
end
