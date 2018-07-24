class CreateMarketTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :market_templates do |t|
      t.string :external_id, null: false
      t.string :name
      t.string :groups
      t.json :payload

      t.timestamps
    end
  end
end
