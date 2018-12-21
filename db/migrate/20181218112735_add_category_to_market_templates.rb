class AddCategoryToMarketTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :market_templates, :category, :string
  end
end
