class RenameCurrencyCode < ActiveRecord::Migration[5.2]
  def change
    rename_column :currencies, :short_name, :code
  end
end
