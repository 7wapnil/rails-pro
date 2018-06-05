class CreateChangeTypeColumnNames < ActiveRecord::Migration[5.2]
  def change
    rename_column :balances, :type, :kind
    rename_column :entries, :type, :kind
  end
end
