class AddShowCategoryInNavigationToTitles < ActiveRecord::Migration[5.2]
  def change
    add_column :titles, :show_category_in_navigation, :boolean, default: true
  end
end
