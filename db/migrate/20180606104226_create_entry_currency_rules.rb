class CreateEntryCurrencyRules < ActiveRecord::Migration[5.2]
  def change
    create_table :entry_currency_rules do |t|
      t.references :currency, foreign_key: true
      t.integer :kind
      t.decimal :min_amount, precision: 8, scale: 2
      t.decimal :max_amount, precision: 8, scale: 2

      t.timestamps

      t.index [:currency_id, :kind], unique: true
    end
  end
end
