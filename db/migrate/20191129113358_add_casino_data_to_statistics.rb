class AddCasinoDataToStatistics < ActiveRecord::Migration[5.2]
  def change
    # rubocop:disable Metrics/LineLength
    add_column :customer_statistics, :casino_game_count, :integer, default: 0
    add_column :customer_statistics, :casino_game_wager, :decimal, default: 0.0, precision: 14, scale: 2
    add_column :customer_statistics, :casino_game_payout, :decimal, default: 0.0, precision: 14, scale: 2
    add_column :customer_statistics, :live_casino_count, :integer, default: 0
    add_column :customer_statistics, :live_casino_wager, :decimal, default: 0.0, precision: 14, scale: 2
    add_column :customer_statistics, :live_casino_payout, :decimal, default: 0.0, precision: 14, scale: 2
    # rubocop:enable Metrics/LineLength
  end
end
