class AddKindToCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies,
               :kind,
               :string,
               default: 'fiat',
               null: false
  end
end
