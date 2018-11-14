class CreateBettingLimits < ActiveRecord::Migration[5.2]
  def change
    create_table :betting_limits do |t|
      t.references :customer, foreign_key: true
      t.references :title, foreign_key: true
      t.references :currency, foreign_key: true
      t.integer :live_bet_delay
      t.integer :user_max_bet
      t.decimal :user_stake_factor
      t.integer :max_loss
      t.integer :max_win
      t.decimal :live_stake_factor
    end

    add_index :betting_limits, %i[customer_id title_id], unique: true
  end
end
