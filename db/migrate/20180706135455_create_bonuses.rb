class CreateBonuses < ActiveRecord::Migration[5.2]
  def change # rubocop:disable Metrics/MethodLength
    create_table :bonuses do |t|
      t.string :code
      t.integer :kind
      t.decimal :rollover_multiplier
      t.decimal :max_rollover_per_bet
      t.decimal :max_deposit_match
      t.decimal :min_odds_per_bet
      t.decimal :min_deposit
      t.integer :valid_for_days
      t.datetime :expires_at
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
