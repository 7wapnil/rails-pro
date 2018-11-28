class CreateDepositLimits < ActiveRecord::Migration[5.2]
  def change
    create_table :deposit_limits do |t|
      t.references :customer, foreign_key: true
      t.references :currency, foreign_key: true
      t.integer :range
      t.decimal :value
    end
  end
end
