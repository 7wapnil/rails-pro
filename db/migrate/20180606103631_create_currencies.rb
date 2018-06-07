class CreateCurrencies < ActiveRecord::Migration[5.2]
  def change
    create_table :currencies do |t|
      t.string :name
      t.string :short_name
      t.boolean :primary, default: false

      t.timestamps
    end
  end
end
