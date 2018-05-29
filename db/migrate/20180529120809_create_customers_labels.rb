class CreateCustomersLabels < ActiveRecord::Migration[5.2]
  def change
    create_table :customers_labels, id: false do |t|
      t.belongs_to :customer, index: true
      t.belongs_to :label, index: true
    end
  end
end
