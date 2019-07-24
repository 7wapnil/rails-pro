class MakeCurrencyCodeAndNameUnique < ActiveRecord::Migration[5.2]
  def change
    add_index :currencies, :code, unique: true
    add_index :currencies, :name, unique: true
  end
end
