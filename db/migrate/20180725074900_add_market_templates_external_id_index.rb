class AddMarketTemplatesExternalIdIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :market_templates, :external_id
  end
end
