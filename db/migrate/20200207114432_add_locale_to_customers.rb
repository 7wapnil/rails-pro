class AddLocaleToCustomers < ActiveRecord::Migration[5.2]
  def change
    add_column :customers, :locale, :string, default: 'en'
  end
end
