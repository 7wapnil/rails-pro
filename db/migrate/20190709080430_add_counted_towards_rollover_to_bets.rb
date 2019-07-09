class AddCountedTowardsRolloverToBets < ActiveRecord::Migration[5.2]
  def change
    add_column :bets, :counted_towards_rollover, :boolean, default: false
  end
end
