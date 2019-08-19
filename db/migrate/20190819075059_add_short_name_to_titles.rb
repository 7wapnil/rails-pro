class AddShortNameToTitles < ActiveRecord::Migration[5.2]
  def change
    add_column :titles, :short_name, :string
  end
end
