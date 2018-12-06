class AddPercentageToBonus < ActiveRecord::Migration[5.2]
  def change
    add_column :bonuses, :percentage, :integer
  end
end
