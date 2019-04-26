class AddRepeatableToBonus < ActiveRecord::Migration[5.2]
  def change
    add_column :bonuses, :repeatable, :boolean, default: true, null: false
  end
end
