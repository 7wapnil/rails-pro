class AddExternalNameToTitles < ActiveRecord::Migration[5.2]
  def change
    rename_column :titles, :name, :external_name
    add_column :titles, :name, :string
  end
end
