class ChangeAddressCountryType < ActiveRecord::Migration[5.2]
  def up
    change_column :addresses, :country, :string
  end

  def down
    change_column :addresses, :country, 'integer USING CAST(country AS integer)'
  end
end
