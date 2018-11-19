class RemoveCurrencyFromBettingLimits < ActiveRecord::Migration[5.2]
  def change
    remove_reference :betting_limits, :currency, foreign_key: true
  end
end
