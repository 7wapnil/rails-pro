class AddSportsbookFlagAndMultiplierToBonuses < ActiveRecord::Migration[5.2]
  def change
    add_column :bonuses, :sportsbook, :boolean,
               null: false, default: true
    add_column :customer_bonuses, :sportsbook, :boolean,
               null: false, default: true

    add_column :bonuses, :sportsbook_multiplier, :decimal,
               null: false, default: 1
    add_column :customer_bonuses, :sportsbook_multiplier, :decimal,
               null: false, default: 1
  end
end
