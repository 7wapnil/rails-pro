# frozen_string_literal: true

class AddStatusMessagesToBets < ActiveRecord::Migration[5.2]
  def change
    rename_column :bets, :message, :notification_message
    add_column :bets, :notification_code, :string
  end
end
