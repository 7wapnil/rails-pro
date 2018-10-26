class CreateLabelJoins < ActiveRecord::Migration[5.2]
  def change
    create_table :label_joins do |t|
      t.references :label, foreign_key: true
      t.integer :labelable_id
      t.string :labelable_type
      t.index %i[labelable_id labelable_type]
    end
  end
end
