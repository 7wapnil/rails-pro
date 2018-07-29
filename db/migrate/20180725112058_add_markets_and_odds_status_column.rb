class AddMarketsAndOddsStatusColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :status, :integer
    add_column :odds, :status, :integer
  end
end
