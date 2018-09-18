class AddTradedLiveToEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :traded_live, :boolean, default: false
  end
end
