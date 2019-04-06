class AddPreviousStatusToMarkets < ActiveRecord::Migration[5.2]
  def change
    add_column :markets, :previous_status, :string
  end
end
