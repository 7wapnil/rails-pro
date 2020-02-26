class CreateAffiliates < ActiveRecord::Migration[5.2]
  def change
    create_table :affiliates do |t|
      t.string :name
      t.string :b_tag
      t.decimal :sports_revenue_share
      t.decimal :casino_revenue_share
      t.decimal :cost_per_acquisition

      t.timestamps
    end
  end
end
