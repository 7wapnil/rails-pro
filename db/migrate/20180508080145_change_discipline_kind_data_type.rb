class ChangeDisciplineKindDataType < ActiveRecord::Migration[5.2]
  def change
    change_table :disciplines do |t|
      t.remove :kind
      t.integer :kind, default: 0
    end
  end
end
