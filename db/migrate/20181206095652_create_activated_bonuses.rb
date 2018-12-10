class CreateActivatedBonuses < ActiveRecord::Migration[5.2]
  def change # rubocop:disable  Metrics/MethodLength
    create_table :activated_bonuses do |t|
      t.references :customer
      t.references :wallet
      t.string :code
      t.integer :kind
      t.decimal :rollover_multiplier
      t.decimal :max_rollover_per_bet
      t.decimal :max_deposit_match
      t.decimal :min_odds_per_bet
      t.decimal :min_deposit
      t.integer :valid_for_days
      t.integer :percentage
      t.datetime :expires_at
      t.integer :original_bonus_id
      t.datetime :activated_at
      t.datetime :deleted_at, index: true
      t.timestamps
    end
  end
end
