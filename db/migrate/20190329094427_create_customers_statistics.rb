class CreateCustomersStatistics < ActiveRecord::Migration[5.2]
  # rubocop:disable Metrics/MethodLength
  def change
    create_table :customer_statistics do |t|
      t.integer :deposit_count,          default: 0
      t.decimal :deposit_value,          default: 0.0, precision: 8, scale: 2
      t.integer :withdrawal_count,       default: 0
      t.decimal :withdrawal_value,       default: 0.0, precision: 8, scale: 2

      t.decimal :theoretical_bonus_cost, default: 0.0, precision: 8, scale: 2
      t.decimal :potential_bonus_cost,   default: 0.0, precision: 8, scale: 2
      t.decimal :actual_bonus_cost,      default: 0.0, precision: 8, scale: 2

      t.integer :prematch_bet_count,     default: 0
      t.decimal :prematch_wager,         default: 0.0, precision: 8, scale: 2
      t.decimal :prematch_payout,        default: 0.0, precision: 8, scale: 2

      t.integer :live_bet_count,         default: 0
      t.decimal :live_sports_wager,      default: 0.0, precision: 8, scale: 2
      t.decimal :live_sports_payout,     default: 0.0, precision: 8, scale: 2

      t.decimal :total_pending_bet_sum,  default: 0.0, precision: 8, scale: 2

      t.references :customer, index: true, foreign_key: true

      t.timestamps
    end
  end
  # rubocop:enable Metrics/MethodLength
end
